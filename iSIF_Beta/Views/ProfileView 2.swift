//
//  ProfileView 2.swift
//  iSayItForward
//
//  Created by Reginald Simon on 10/29/25.
//


import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter   // ✅ Add the shared TabRouter

    // MARK: - State
    @State private var isEditing = false
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender = ""
    @State private var location = ""
    @State private var bio = ""
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showSavedToast = false
    @State private var showDeleteAlert = false

    private let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Theme Constants
    let goldButtonColor = Color(hex: "FFD700")
    let primaryTextColor = Color.black.opacity(0.75)
    let cardBackgroundColor = Color.white.opacity(0.75)
    let cardCornerRadius: CGFloat = 25
    let cardShadowColor = Color.black.opacity(0.1)

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        profileHeader
                        editableProfileCard
                        bioSection
                        privacySection
                        editSaveButton
                        logoutButton
                            .padding(.bottom, 140) // space above nav bar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                }

                // ✅ Add Bottom Navigation Bar
                VStack {
                    Spacer()
                    BottomNavBar()
                        .environmentObject(router)
                        .padding(.bottom, 10)
                }

                if showSavedToast { savedToast }
            }
            .navigationBarHidden(true)
            .task {
                await loadUserData()
                await loadProfileImageIfAvailable()
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAccount() }
            } message: {
                Text("This will permanently remove your profile and all related data.")
            }
        }
    }

    // MARK: - Header Section
    private var profileHeader: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .shadow(color: cardShadowColor, radius: 10, y: 6)

                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Change Profile Picture")
                    .font(.custom("AvenirNext-SemiBold", size: 16))
                    .foregroundColor(Color(hex: "132E37"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .background(Capsule().fill(Color.white.opacity(0.6)))
                    .shadow(color: cardShadowColor, radius: 3, y: 1)
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
    }

    // MARK: - Editable Info Card
    private var editableProfileCard: some View {
        VStack(spacing: 18) {
            EditableField(title: "Name", text: $userName, icon: "person.fill", isEditing: isEditing)
            EditableField(title: "Email", text: $userEmail, icon: "envelope.fill", isEditing: false)
            EditableField(title: "Phone", text: $phoneNumber, icon: "phone.fill", isEditing: isEditing)
            EditableField(title: "Location", text: $location, icon: "mappin.and.ellipse", isEditing: isEditing)

            if isEditing {
                HStack {
                    Image(systemName: "calendar").foregroundColor(.gray)
                    DatePicker("Birth Date", selection: $dateOfBirth, displayedComponents: .date)
                        .font(.custom("AvenirNext-Regular", size: 15))
                        .foregroundColor(primaryTextColor)
                }
                .padding()
                .background(.white.opacity(0.9))
                .cornerRadius(14)

                HStack {
                    Image(systemName: "person.2.fill").foregroundColor(.gray)
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { Text($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .tint(primaryTextColor)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.white.opacity(0.9))
                .cornerRadius(14)
            }
        }
        .padding(25)
        .background(cardBackgroundColor)
        .cornerRadius(cardCornerRadius)
        .shadow(color: cardShadowColor, radius: 10, y: 4)
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About Me")
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 5)

            ProfileTextArea(title: "Write something about yourself...", text: $bio, isEditing: isEditing, minHeight: 150)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data & Privacy")
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 5)

            VStack(spacing: 12) {
                Button(action: downloadPersonalData) {
                    Label("Download Personal Data", systemImage: "arrow.down.doc.fill")
                        .font(.custom("AvenirNext-Medium", size: 15))
                        .foregroundColor(primaryTextColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.9))
                        .cornerRadius(14)
                        .shadow(color: cardShadowColor, radius: 3, y: 2)
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete My Account", systemImage: "trash.fill")
                        .font(.custom("AvenirNext-Medium", size: 15))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(14)
                        .shadow(color: cardShadowColor, radius: 3, y: 2)
                }
            }
        }
    }

    private var editSaveButton: some View {
        Button(action: toggleEdit) {
            Text(isEditing ? "Save Changes" : "Edit Profile")
                .font(.custom("AvenirNext-Bold", size: 18))
                .foregroundColor(primaryTextColor)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(goldButtonColor)
                        .shadow(color: cardShadowColor, radius: 5, y: 3)
                )
        }
        .padding(.horizontal, 40)
    }

    private var logoutButton: some View {
        Button(action: signOut) {
            Text("Log out")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(primaryTextColor.opacity(0.7))
                .underline()
        }
    }

    private var savedToast: some View {
        VStack {
            Spacer()
            Text("✅ Profile Updated!")
                .font(.custom("AvenirNext-SemiBold", size: 15))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 25)
                .background(Capsule().fill(Color.green.opacity(0.9)))
                .shadow(radius: 3)
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Firestore & Firebase
    private func loadUserData() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            guard let data = snapshot.data() else { return }
            await MainActor.run {
                userName = data["displayName"] as? String ?? ""
                userEmail = data["email"] as? String ?? ""
                phoneNumber = data["phone"] as? String ?? ""
                gender = data["gender"] as? String ?? ""
                location = data["location"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                if let dobString = data["dateOfBirth"] as? String,
                   let dob = ISO8601DateFormatter().date(from: dobString) {
                    dateOfBirth = dob
                }
            }
        } catch {
            print("❌ Firestore load error: \(error.localizedDescription)")
        }
    }

    private func saveProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let userData: [String: Any] = [
            "displayName": userName,
            "email": userEmail,
            "phone": phoneNumber,
            "gender": gender,
            "location": location,
            "bio": bio,
            "dateOfBirth": ISO8601DateFormatter().string(from: dateOfBirth)
        ]
        do {
            try await db.collection("users").document(uid).setData(userData, merge: true)
            await MainActor.run {
                withAnimation { showSavedToast = true }
            }
            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { showSavedToast = false }
            }
        } catch {
            print("❌ Error saving profile: \(error.localizedDescription)")
        }
    }

    private func uploadProfileImage(_ image: UIImage) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        do {
            _ = try await storageRef.putDataAsync(imageData)
            let url = try await storageRef.downloadURL()
            try await db.collection("users").document(uid).setData(["photoURL": url.absoluteString], merge: true)
        } catch {
            print("❌ Error uploading image: \(error.localizedDescription)")
        }
    }

    private func loadProfileImageIfAvailable() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            guard let data = snapshot.data(),
                  let photoURL = data["photoURL"] as? String,
                  let url = URL(string: photoURL) else { return }

            let (imageData, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: imageData) {
                await MainActor.run { self.profileImage = uiImage }
            }
        } catch {
            print("❌ Failed to load profile image: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private func toggleEdit() {
        Task {
            if isEditing { await saveProfile() }
            await MainActor.run { withAnimation { isEditing.toggle() } }
        }
    }

    private func signOut() {
        authState.signOut()
    }

    private func downloadPersonalData() {
        print("📥 User requested personal data export.")
    }

    private func deleteAccount() {
        print("🗑️ User account deletion initiated.")
    }

    // MARK: - Subviews
    private struct EditableField: View {
        let title: String
        @Binding var text: String
        let icon: String
        let isEditing: Bool
        let primaryTextColor = Color.black.opacity(0.75)

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.gray)
                    .padding(.leading, 6)

                HStack(spacing: 12) {
                    Image(systemName: icon).foregroundColor(.gray).frame(width: 20)
                    if isEditing {
                        TextField("", text: $text)
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(primaryTextColor)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        Text(text.isEmpty ? "—" : text)
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }

    private struct ProfileTextArea: View {
        let title: String
        @Binding var text: String
        let isEditing: Bool
        var minHeight: CGFloat = 100
        let primaryTextColor = Color.black.opacity(0.75)

        var body: some View {
            Group {
                if isEditing {
                    TextEditor(text: $text)
                        .frame(minHeight: minHeight)
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(primaryTextColor)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                } else {
                    Text(text.isEmpty ? "No bio added yet." : text)
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthState())
        .environmentObject(TabRouter())
}