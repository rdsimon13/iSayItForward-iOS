import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Centralized Firebase Authentication & Firestore manager
/// Handles all user login, registration, phone verification, and profile persistence logic.
@MainActor
final class AppAuthManager: ObservableObject {

    // MARK: - Published Properties
    /// The currently signed-in Firebase user (automatically updated via listener)
    @Published var currentUser: FirebaseAuth.User? = Auth.auth().currentUser

    // MARK: - Firestore Reference
    private let db = Firestore.firestore()

    // MARK: - Initialization
    init() {
        // Listen for authentication state changes in real time
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    // MARK: - Email Authentication

    /// Signs in an existing user with email & password.
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown sign-in error"]
                    ))
                }
            }
        }
    }

    /// Registers a new user with email & password.
    func register(email: String, password: String) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown registration error"]
                    ))
                }
            }
        }
    }

    /// Signs the current user out and updates state.
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    // MARK: - Phone Verification (Optional Login Support)

    /// Sends an SMS verification code to a phone number.
    func sendPhoneVerification(to phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let verificationID = verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown verification error"]
                    ))
                }
            }
        }
    }

    /// Signs in a user with a previously sent SMS verification code.
    func signInWithVerificationCode(verificationID: String, verificationCode: String) async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "Auth",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown phone sign-in error"]
                    ))
                }
            }
        }
    }

    // MARK: - Firestore User Profile Management

    /// Saves or updates the user's Firestore profile document.
    ///
    /// - Parameters:
    ///   - uid: The user ID from FirebaseAuth.
    ///   - data: A dictionary containing profile information (firstName, lastName, etc.).
    func saveUserProfile(uid: String, data: [String: Any]) async throws {
        print("📦 Attempting to save Firestore profile for UID: \(uid)")
        let userRef = db.collection("users").document(uid)
        do {
            try await userRef.setData(data, merge: true)
            print("✅ Firestore profile save complete for UID: \(uid)")
        } catch {
            print("❌ Firestore profile save failed for UID: \(uid) — \(error.localizedDescription)")
            throw error
        }
    }

    /// Retrieves an email address associated with a given phone number (if any).
    func getEmailForPhoneNumber(_ phoneNumber: String) async throws -> String? {
        let snapshot = try await db.collection("users")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .getDocuments()

        return snapshot.documents.first?.data()["email"] as? String
    }

    // MARK: - Delete Account (Optional Future Use)

    /// Deletes the user's authentication record and Firestore document.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }

        do {
            try await db.collection("users").document(user.uid).delete()
            try await user.delete()
            currentUser = nil
            print("🗑️ User account deleted successfully: \(user.uid)")
        } catch {
            print("❌ Error deleting user account: \(error.localizedDescription)")
            throw error
        }
    }
}
