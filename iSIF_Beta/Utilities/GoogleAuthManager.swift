import UIKit
import FirebaseAuth
import FirebaseCore
//import GoogleSignIn

// MARK: - Google Auth Manager
/*final class GoogleAuthManager {
    static let shared = GoogleAuthManager()
    private init() {}

    /// Presents Google Sign-In, then signs in to Firebase.
    func signIn(presenting presenter: UIViewController? = UIApplication.topViewController(),
                completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {

        guard let presenter = presenter else {
            completion(.failure(NSError(domain: "GoogleAuth",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "No presenting controller"])))
            return
        }

        // Configure with Firebase clientID
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "GoogleAuth",
                                        code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "Missing Firebase clientID"])))
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        // 1) Google sheet
        GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                completion(.failure(NSError(domain: "GoogleAuth",
                                            code: -3,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing Google tokens"])))
                return
            }

            // 2) Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            // 3) Firebase sign-in
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                } else if let fbUser = authResult?.user {
                    completion(.success(fbUser))
                } else {
                    completion(.failure(NSError(domain: "GoogleAuth",
                                                code: -4,
                                                userInfo: [NSLocalizedDescriptionKey: "Firebase user not found"])) )
                }
            }
        }
    }
}
*/
// MARK: - Top-most VC helper
extension UIApplication {
    static func topViewController(base: UIViewController? = UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?
        .rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
