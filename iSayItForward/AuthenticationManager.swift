import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices

// MARK: - Authentication Error Types
enum AuthenticationError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknownError(String)
    case googleSignInFailed
    case appleSignInFailed
    case signOutFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPassword:
            return "Password must be at least 6 characters long."
        case .userNotFound:
            return "No account found with this email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please choose a stronger password."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknownError(let message):
            return message
        case .googleSignInFailed:
            return "Google Sign In failed. Please try again."
        case .appleSignInFailed:
            return "Apple Sign In failed. Please try again."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        }
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    func signIn(email: String, password: String) async {
        guard validateEmail(email) else {
            errorMessage = AuthenticationError.invalidEmail.errorDescription
            return
        }
        
        guard validatePassword(password) else {
            errorMessage = AuthenticationError.invalidPassword.errorDescription
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
        } catch let error as NSError {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        guard validateEmail(email) else {
            errorMessage = AuthenticationError.invalidEmail.errorDescription
            return
        }
        
        guard validatePassword(password) else {
            errorMessage = AuthenticationError.invalidPassword.errorDescription
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
            isAuthenticated = true
        } catch let error as NSError {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let presentingViewController = window.rootViewController else {
            errorMessage = AuthenticationError.googleSignInFailed.errorDescription
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase client ID not found."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Configure Google Sign In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start the sign in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                errorMessage = AuthenticationError.googleSignInFailed.errorDescription
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            isAuthenticated = true
            
        } catch {
            errorMessage = AuthenticationError.googleSignInFailed.errorDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            // This method needs to be called from a UI context with proper delegation
            // The actual implementation will be handled by the UI component
            errorMessage = "Please use the Sign in with Apple button for Apple authentication."
            
        } catch {
            errorMessage = AuthenticationError.appleSignInFailed.errorDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In with Credential (called from UI)
    func signInWithAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let nonce = generateNonce() else {
                errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                isLoading = false
                return
            }
            
            guard let appleIDToken = credential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                isLoading = false
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                isLoading = false
                return
            }
            
            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                            idToken: idTokenString,
                                                            rawNonce: nonce)
            
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            user = result.user
            isAuthenticated = true
            
        } catch {
            errorMessage = AuthenticationError.appleSignInFailed.errorDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async {
        guard validateEmail(email) else {
            errorMessage = AuthenticationError.invalidEmail.errorDescription
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "Password reset email sent successfully."
        } catch let error as NSError {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            try GIDSignIn.sharedInstance.signOut()
            user = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = AuthenticationError.signOutFailed.errorDescription
        }
    }
    
    // MARK: - Validation Helpers
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            errorMessage = AuthenticationError.invalidEmail.errorDescription
        case AuthErrorCode.userNotFound.rawValue:
            errorMessage = AuthenticationError.userNotFound.errorDescription
        case AuthErrorCode.wrongPassword.rawValue:
            errorMessage = AuthenticationError.wrongPassword.errorDescription
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            errorMessage = AuthenticationError.emailAlreadyInUse.errorDescription
        case AuthErrorCode.weakPassword.rawValue:
            errorMessage = AuthenticationError.weakPassword.errorDescription
        case AuthErrorCode.networkError.rawValue:
            errorMessage = AuthenticationError.networkError.errorDescription
        default:
            errorMessage = AuthenticationError.unknownError(error.localizedDescription).errorDescription
        }
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Nonce Generation for Apple Sign In
    private func generateNonce() -> String? {
        // Generate a cryptographically secure nonce for Apple Sign In
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = 32
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// MARK: - Apple Sign In Coordinator
struct AppleSignInCoordinator: UIViewControllerRepresentable {
    @ObservedObject var authManager: AuthenticationManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: AppleSignInCoordinator
        
        init(_ parent: AppleSignInCoordinator) {
            self.parent = parent
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return UIApplication.shared.windows.first ?? ASPresentationAnchor()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await parent.authManager.signInWithAppleCredential(appleIDCredential)
                }
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.authManager.errorMessage = AuthenticationError.appleSignInFailed.errorDescription
            parent.authManager.isLoading = false
        }
    }
}