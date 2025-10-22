import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    
    // MARK: - State Variables
    @State private var isEditing = false
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender = ""
    @State private var location = ""
    
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedTab: String = "profile"
    @State private var showSavedToast = false
    @State private var scrollOffset: CGFloat = 0

    private let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 25) {
                            profileHeader
                            EditableProfileForm(
                                userName: $userName,
                                userEmail: $userEmail,
                                phoneNumber: $phoneNumber,
                                dateOfBirth: $dateOfBirth,
                                gender: $gender,
                                location: $location,
                                genders: genders,
                                isEditing: isEditing
                            )
                            editSaveButton
                            logoutButton
                        }
                        .padding(.bottom, 100)
                        .trackScrollOffset(in: "scroll", offset: $scrollOffset)
                    }
                    .coordinateSpace(name: "scroll")

                    // ✅ Updated BottomNavBar usage (binding-safe)
                    BottomNavBar(selectedTab: $selectedTab, scrollOffsetBinding: $scrollOffset)
                        .padding(.bottom, 5)
                        .onChange(of: selectedTab) { newTab in
                            navigateTo(tab: newTab)
                        }
                }

                if showSavedToast {
                    savedToast
                }
            }
            .task {
                await loadUserData()
                await loadProfileImageIfAvailable()
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                .init(color: Color.white, location: 1.0)
            ]),
            center: .top,
            startRadius: 0,
            endRadius: UIScreen.main.bounds.height * 1.0
        )
        .ignoresSafeArea()
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
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
                    .font(.custom("Kodchasan-Regular", size: 15))
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
        .padding(.top, 50)
    }

    // MARK: - Edit / Save Button
    private var editSaveButton: some View {
        Button(action: toggleEdit) {
            Text(isEditing ? "Save Changes" : "Edit Profile")
                .font(.custom("Kodchasan-SemiBold", size: 17))
                .foregroundColor(Color.black.opacity(0.85))
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(GradientTheme.goldPill)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                )
        }
        .padding(.horizontal, 60)
        .padding(.top, 5)
        .padding(.bottom, 30)
    }

    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: signOut) {
            Text("Log out")
                .font(.custom("Kodchasan-Regular", size: 14))
                .foregroundColor(.black.opacity(0.6))
                .underline()
        }
        .padding(.bottom, 80)
    }

    // MARK: - Saved Toast
    private var savedToast: some View {
        VStack {
            Spacer()
            Text("✅ Profile updated successfully!")
                .font(.custom("Kodchasan-SemiBold", size: 15))
                .foregroundColor(.white)
                .padding()
                .background(Capsule().fill(Color.green.opacity(0.9)))
                .shadow(radius: 3)
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Firestore Functions (Async/Await)
    private func loadUserData() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            guard let data = snapshot.data() else { return }

            await MainActor.run {
                self.userName = data["displayName"] as? String ?? ""
                self.userEmail = data["email"] as? String ?? ""
                self.phoneNumber = data["phone"] as? String ?? ""
                self.gender = data["gender"] as? String ?? ""
                self.location = data["location"] as? String ?? ""
                if let dobString = data["dateOfBirth"] as? String,
                   let dob = ISO8601DateFormatter().date(from: dobString) {
                    self.dateOfBirth = dob
                }
            }
            print("✅ Loaded user data from Firestore.")
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
            "dateOfBirth": ISO8601DateFormatter().string(from: dateOfBirth)
        ]

        do {
            try await db.collection("users").document(uid).setData(userData, merge: true)

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = userName
            try await changeRequest.commitChanges()

            await MainActor.run {
                withAnimation { showSavedToast = true }
            }

            print("✅ Profile successfully updated in Firestore & Auth.")

            try await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { showSavedToast = false }
            }
        } catch {
            print("❌ Error saving profile: \(error.localizedDescription)")
        }
    }

    private func toggleEdit() {
        Task {
            if isEditing { await saveProfile() }
            await MainActor.run {
                withAnimation { isEditing.toggle() }
            }
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
            print("✅ Uploaded profile image and updated Firestore with URL.")
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
                print("🖼️ Loaded profile image from Firestore URL.")
            }
        } catch {
            print("❌ Failed to load profile image: \(error.localizedDescription)")
        }
    }

    private func signOut() {
        authState.signOut()
        print("🚪 User signed out.")
    }

    // MARK: - Navigation
    private func navigateTo(tab: String) {
        switch tab {
        case "home": navigate(to: DashboardView())
        case "compose": navigate(to: CreateSIFView())
        case "profile": break
        case "schedule": navigate(to: ScheduleSIFView())
        case "settings": navigate(to: GettingStartedView())
        default: break
        }
    }

    private func navigate<Destination: View>(to destination: Destination) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = UIHostingController(rootView: destination)
        window.makeKeyAndVisible()
    }
}

// MARK: - Editable Profile Form
private struct EditableProfileForm: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var phoneNumber: String
    @Binding var dateOfBirth: Date
    @Binding var gender: String
    @Binding var location: String
    let genders: [String]
    let isEditing: Bool

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }

    var body: some View {
        VStack(spacing: 18) {
            ProfileField(title: "Full Name", text: $userName, icon: "person.fill", isEditing: isEditing)
            ProfileField(title: "Email", text: $userEmail, icon: "envelope.fill", isEditing: false)
            ProfileField(title: "Phone Number", text: $phoneNumber, icon: "phone.fill", isEditing: isEditing)

            if isEditing {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .font(.custom("Kodchasan-Regular", size: 15))
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(14)

                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.gray)
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(14)
            } else {
                InfoRow(icon: "calendar", label: "Date of Birth", value: dateFormatter.string(from: dateOfBirth))
                InfoRow(icon: "person.2.fill", label: "Gender", value: gender.isEmpty ? "Not specified" : gender)
            }

            ProfileField(title: "Location", text: $location, icon: "mappin.and.ellipse", isEditing: isEditing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(Color.white.opacity(0.85))
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
        .padding(.horizontal, 32)
    }
}

// MARK: - Subviews
private struct ProfileField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var isEditing: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            if isEditing {
                TextField(title, text: $text)
                    .font(.custom("Kodchasan-Regular", size: 15))
                    .foregroundColor(.black.opacity(0.9))
                    .autocapitalization(.none)
            } else {
                Text(text.isEmpty ? "—" : text)
                    .font(.custom("Kodchasan-Regular", size: 15))
                    .foregroundColor(.black.opacity(0.8))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.custom("Kodchasan-Regular", size: 13))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.custom("Kodchasan-Regular", size: 15))
                    .foregroundColor(.black.opacity(0.85))
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthState())
}
