import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @StateObject private var userDataManager = UserDataManager()
    @StateObject private var imageManager = ProfileImageManager()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingImagePicker = false
    @State private var showingEditBio = false
    @State private var showingEditName = false
    @State private var editingBio = ""
    @State private var editingName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Profile")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                            
                            // Profile Image Section
                            ProfileImageSection(
                                imageManager: imageManager,
                                userDataManager: userDataManager,
                                selectedPhotoItem: $selectedPhotoItem
                            )
                            
                            // User Info Section
                            if let user = userDataManager.currentUser {
                                UserInfoSection(
                                    user: user,
                                    onEditName: {
                                        editingName = user.displayName ?? user.name
                                        showingEditName = true
                                    },
                                    onEditBio: {
                                        editingBio = user.bio ?? ""
                                        showingEditBio = true
                                    }
                                )
                            }
                        }
                        
                        // Statistics Section
                        if let user = userDataManager.currentUser {
                            StatisticsSection(user: user)
                        }
                        
                        // Settings Navigation
                        SettingsNavigationSection()
                        
                        // Logout Button
                        Button("Log Out") {
                            signOut()
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                        
                        if userDataManager.isLoading {
                            ProgressView("Loading...")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .alert("Profile", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingEditName) {
                EditNameSheet(
                    currentName: editingName,
                    onSave: { newName in
                        Task {
                            await userDataManager.updateUserField(\.displayName, value: newName)
                            if let error = userDataManager.errorMessage {
                                alertMessage = error
                                showingAlert = true
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showingEditBio) {
                EditBioSheet(
                    currentBio: editingBio,
                    onSave: { newBio in
                        Task {
                            await userDataManager.updateUserField(\.bio, value: newBio.isEmpty ? nil : newBio)
                            if let error = userDataManager.errorMessage {
                                alertMessage = error
                                showingAlert = true
                            }
                        }
                    }
                )
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        imageManager.selectedImage = image
                        
                        if let imageUrl = await imageManager.uploadProfileImage(image) {
                            await userDataManager.updateUserField(\.profileImageUrl, value: imageUrl)
                        }
                        
                        if let error = imageManager.errorMessage {
                            alertMessage = error
                            showingAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            alertMessage = "Error signing out: \(signOutError.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Supporting Views

private struct ProfileImageSection: View {
    let imageManager: ProfileImageManager
    let userDataManager: UserDataManager
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .shadow(radius: 5)
                
                if let profileImage = imageManager.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.8))
                        .padding(15)
                }
                
                if imageManager.isLoading {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
                
                // Edit button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.brandDarkBlue)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .offset(x: 40, y: 40)
            }
            .frame(width: 130, height: 130)
            
            if imageManager.uploadProgress > 0 && imageManager.uploadProgress < 1 {
                ProgressView(value: imageManager.uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 130)
            }
        }
        .onAppear {
            Task {
                await imageManager.loadProfileImage(from: userDataManager.currentUser?.profileImageUrl)
            }
        }
    }
}

private struct UserInfoSection: View {
    let user: User
    let onEditName: () -> Void
    let onEditBio: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Name and Edit Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? user.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit", action: onEditName)
                    .font(.caption)
                    .foregroundColor(Color.brandDarkBlue)
            }
            
            Divider()
            
            // Bio Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bio")
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(user.bio?.isEmpty == false ? user.bio! : "Add a bio to tell others about yourself")
                        .font(.body)
                        .foregroundColor(user.bio?.isEmpty == false ? .primary : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button("Edit", action: onEditBio)
                    .font(.caption)
                    .foregroundColor(Color.brandDarkBlue)
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

private struct StatisticsSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatCard(title: "SIFs Created", value: "\(user.sifsCreated)", icon: "square.and.pencil")
                StatCard(title: "SIFs Sent", value: "\(user.sifsSent)", icon: "paperplane.fill")
                StatCard(title: "SIFs Received", value: "\(user.sifsReceived)", icon: "tray.full.fill")
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.brandDarkBlue)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
    }
}

private struct SettingsNavigationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                NavigationLink(destination: NotificationSettingsView()) {
                    SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage notification preferences")
                }
                
                Divider()
                
                NavigationLink(destination: PrivacySettingsView()) {
                    SettingsRow(icon: "lock.shield.fill", title: "Privacy", subtitle: "Control your privacy settings")
                }
                
                Divider()
                
                NavigationLink(destination: AccountSettingsView()) {
                    SettingsRow(icon: "gearshape.fill", title: "Account", subtitle: "Manage your account details")
                }
            }
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
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
}

// MARK: - Edit Sheets

private struct EditNameSheet: View {
    @State private var name: String
    let onSave: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(currentName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: currentName)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Display Name", text: $name)
                        .textFieldStyle(PillTextFieldStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave(name)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

private struct EditBioSheet: View {
    @State private var bio: String
    let onSave: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(currentBio: String, onSave: @escaping (String) -> Void) {
        _bio = State(initialValue: currentBio)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                            .padding()
                            .background(.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brandDarkBlue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Bio")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave(bio)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    ProfileView()
}
