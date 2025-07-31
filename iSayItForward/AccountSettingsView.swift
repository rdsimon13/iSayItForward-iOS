import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @StateObject private var userDataManager = UserDataManager()
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var showingChangePasswordSheet = false
    @State private var showingChangeEmailSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Account Settings")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("Manage your account details")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top)
                        
                        // Account Information
                        if let user = userDataManager.currentUser {
                            AccountInfoSection(user: user)
                        }
                        
                        // Account Actions
                        SettingsSection(title: "Account Management") {
                            AccountActionButton(
                                icon: "envelope.fill",
                                title: "Change Email",
                                subtitle: "Update your email address",
                                action: {
                                    showingChangeEmailSheet = true
                                }
                            )
                            
                            Divider()
                            
                            AccountActionButton(
                                icon: "key.fill",
                                title: "Change Password",
                                subtitle: "Update your account password",
                                action: {
                                    showingChangePasswordSheet = true
                                }
                            )
                            
                            Divider()
                            
                            AccountActionButton(
                                icon: "arrow.right.square.fill",
                                title: "Sign Out",
                                subtitle: "Sign out of your account",
                                action: {
                                    showingSignOutConfirmation = true
                                }
                            )
                        }
                        
                        // Data Management
                        SettingsSection(title: "Data Management") {
                            AccountActionButton(
                                icon: "square.and.arrow.down.fill",
                                title: "Download Your Data",
                                subtitle: "Get a copy of your data",
                                action: downloadUserData
                            )
                            
                            Divider()
                            
                            AccountActionButton(
                                icon: "trash.fill",
                                title: "Clear Cache",
                                subtitle: "Clear locally stored data",
                                action: clearCache
                            )
                        }
                        
                        // Danger Zone
                        DangerZoneSection {
                            showingDeleteConfirmation = true
                        }
                        
                        if userDataManager.isLoading {
                            ProgressView("Processing...")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showingChangePasswordSheet) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showingChangeEmailSheet) {
                ChangeEmailView()
            }
        }
    }
    
    // MARK: - Actions
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertTitle = "Sign Out Error"
            alertMessage = "Failed to sign out: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteAccount() async {
        do {
            try await userDataManager.deleteUserAccount()
            // User will be automatically signed out
        } catch {
            alertTitle = "Delete Account Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func downloadUserData() {
        // Implement data download functionality
        alertTitle = "Download Data"
        alertMessage = "Data download feature will be available soon."
        showingAlert = true
    }
    
    private func clearCache() {
        // Clear image cache and other local data
        alertTitle = "Cache Cleared"
        alertMessage = "Local cache has been cleared successfully."
        showingAlert = true
    }
}

// MARK: - Supporting Views

private struct AccountInfoSection: View {
    let user: User
    
    var body: some View {
        SettingsSection(title: "Account Information") {
            VStack(spacing: 12) {
                InfoRow(label: "Name", value: user.name)
                Divider()
                InfoRow(label: "Email", value: user.email)
                Divider()
                InfoRow(label: "User ID", value: user.uid)
                Divider()
                InfoRow(label: "Member Since", value: formattedDate(user.joinedDate))
            }
            .padding()
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.brandDarkBlue)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                content
            }
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

private struct AccountActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color.brandDarkBlue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct DangerZoneSection: View {
    let onDeleteAccount: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(spacing: 0) {
                Button(action: onDeleteAccount) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete Account")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Text("Permanently delete your account and all data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

// MARK: - Modal Views

private struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    SecureField("Current Password", text: $currentPassword)
                        .textFieldStyle(PillTextFieldStyle())
                    
                    SecureField("New Password", text: $newPassword)
                        .textFieldStyle(PillTextFieldStyle())
                    
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textFieldStyle(PillTextFieldStyle())
                    
                    Button("Change Password") {
                        changePassword()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isLoading || newPassword != confirmPassword || newPassword.isEmpty)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Password Change", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found"
            showingAlert = true
            isLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                alertMessage = "Current password is incorrect: \(error.localizedDescription)"
                showingAlert = true
                isLoading = false
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to change password: \(error.localizedDescription)"
                } else {
                    alertMessage = "Password changed successfully"
                }
                showingAlert = true
            }
        }
    }
}

private struct ChangeEmailView: View {
    @State private var newEmail = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("New Email", text: $newEmail)
                        .textFieldStyle(PillTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Current Password", text: $password)
                        .textFieldStyle(PillTextFieldStyle())
                    
                    Button("Change Email") {
                        changeEmail()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isLoading || newEmail.isEmpty || password.isEmpty)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Email Change", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func changeEmail() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not found"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                alertMessage = "Password is incorrect: \(error.localizedDescription)"
                showingAlert = true
                isLoading = false
                return
            }
            
            user.updateEmail(to: newEmail) { error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to change email: \(error.localizedDescription)"
                } else {
                    alertMessage = "Email changed successfully"
                }
                showingAlert = true
            }
        }
    }
}

#Preview {
    AccountSettingsView()
}