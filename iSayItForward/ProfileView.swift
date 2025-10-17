import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    @State private var isEditing = false
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // MARK: - Profile Header
                    VStack(spacing: 10) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 130)
                                .foregroundColor(.gray.opacity(0.5))
                                .shadow(radius: 4)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change Profile Picture")
                                .font(TextStyles.subtitle(15))
                                .foregroundColor(.blue)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let newItem,
                                   let data = try? await newItem.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = uiImage
                                    await uploadProfileImage(uiImage)
                                }
                            }
                        }
                    }
                    .padding(.top, 40)

                    // MARK: - User Info Card
                    FrostedRoundedCard {
                        VStack(alignment: .leading, spacing: 14) {
                            if isEditing {
                                CapsuleField(placeholder: "Full Name", text: $userName)
                                CapsuleField(placeholder: "Email", text: $userEmail)
                            } else {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                    Text(userName)
                                        .font(TextStyles.subtitle(16))
                                        .foregroundColor(.black.opacity(0.85))
                                }

                                Divider()

                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.gray)
                                    Text(userEmail)
                                        .font(TextStyles.subtitle(16))
                                        .foregroundColor(.black.opacity(0.85))
                                }
                            }

                            // MARK: - Edit Button
                            HStack(spacing: 14) {
                                Button(action: toggleEdit) {
                                    Text(isEditing ? "Save" : "Edit Profile")
                                        .font(TextStyles.subtitle(17))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            Capsule()
                                                .fill(GradientTheme.primaryPill)
                                                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                                        )
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Sign Out Button
                    Button(action: signOut) {
                        Text("Log Out")
                            .font(TextStyles.subtitle(17))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.8))
                                    .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                            )
                            .padding(.horizontal, 60)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 20)
            }
        }
        .onAppear(perform: loadUserData)
    }

    // MARK: - Logic
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            userName = user.displayName ?? "User"
            userEmail = user.email ?? "user@example.com"
        }
    }

    private func toggleEdit() {
        if isEditing {
            saveToAuthProfile()
        }
        withAnimation { isEditing.toggle() }
    }

    private func saveToAuthProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = userName
        changeRequest.commitChanges { error in
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
            } else {
                print("✅ Profile updated successfully.")
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) async {
        // TODO: Upload to Firebase Storage if required.
        print("🖼️ Uploaded image placeholder logic executed.")
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out")
        } catch {
            print("❌ Sign-out error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView()
}
