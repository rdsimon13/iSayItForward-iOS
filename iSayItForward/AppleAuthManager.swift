import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import UIKit
import FirebaseFirestore // ✅ Import Firestore to save user data

final class AppleAuthManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleAuthManager()

    private var completionHandler: ((Result<iSayItForward.User, Error>) -> Void)?
    private var currentNonce: String?

    // MARK: - Public entry point
    func startSignInWithAppleFlow(completion: @escaping (Result<iSayItForward.User, Error>) -> Void) {
        self.completionHandler = completion
        let nonce = randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completionHandler?(.failure(makeError("Invalid Apple credential.")))
            cleanup()
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            completionHandler?(.failure(makeError("Unable to parse identity token.")))
            cleanup()
            return
        }

        guard let nonce = currentNonce else {
            completionHandler?(.failure(makeError("Missing nonce.")))
            cleanup()
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            // ✅ FIX #1: Dispatch to the main thread to prevent UI-related crashes.
            DispatchQueue.main.async {
                if let error = error {
                    self.completionHandler?(.failure(error))
                    self.cleanup()
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self.completionHandler?(.failure(self.makeError("Firebase user data missing.")))
                    self.cleanup()
                    return
                }

                // ✅ FIX #2: Handle one-time data fetch.
                // Apple only sends the name and email the VERY FIRST TIME.
                // We check if this is a new user and if we received the name data.
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                if isNewUser, let fullName = appleIDCredential.fullName {
                    // This is a brand-new user; create their full profile and save to Firestore.
                    let newUser = iSayItForward.User(
                        firstName: fullName.givenName ?? "",
                        lastName: fullName.familyName ?? "",
                        email: firebaseUser.email ?? "",
                        uid: firebaseUser.uid
                    )
                    self.saveUserToFirestore(user: newUser)
                    print("🍎 New Apple user created and saved to Firestore: \(newUser.email)")
                    self.completionHandler?(.success(newUser))
                } else {
                    // This is a returning user. Their name and email are NOT in the credential.
                    // You should fetch their profile from your Firestore database using the UID.
                    // For now, we'll construct a user object with the available info.
                    let returningUser = iSayItForward.User(
                        firstName: firebaseUser.displayName ?? "", // Might be nil or just email
                        lastName: "",
                        email: firebaseUser.email ?? "",
                        uid: firebaseUser.uid
                    )
                    print("🍎 Returning Apple user signed in: \(returningUser.email)")
                    self.completionHandler?(.success(returningUser))
                }
                
                self.cleanup()
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(.failure(error))
        cleanup()
    }

    // MARK: - Presentation anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    // MARK: - Helpers
    private func saveUserToFirestore(user: iSayItForward.User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "uid": user.uid,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("🔥 Error saving user to Firestore: \(error.localizedDescription)")
            } else {
                print("✅ User data successfully saved to Firestore.")
            }
        }
    }
    
    // ✅ FIX #3: Added a cleanup function to reset state and prevent memory leaks.
    private func cleanup() {
        completionHandler = nil
        currentNonce = nil
    }

    private func makeError(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "AppleAuth", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if status != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
        }
        return randomBytes.map { byte in
            String(format: "%02x", byte)
        }.joined()
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
