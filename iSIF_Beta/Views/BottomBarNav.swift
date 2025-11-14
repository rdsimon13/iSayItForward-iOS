import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct BottomNavBar: View {
    @Binding var selectedTab: AppTab
    @Binding var isVisible: Bool
    @EnvironmentObject var authState: AuthState
    @State private var profileImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            if tab == .profile, let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(selectedTab == tab ? Color.blue : Color.gray, lineWidth: 2))
                            } else {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                            }

                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 34) // Extra padding for iPhone home indicator
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 2)
        )
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            loadProfileImage()
        }
        .onChange(of: authState.currentUser) { _ in
            loadProfileImage()
        }
    }

    private func loadProfileImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            let storage = Storage.storage()
            let storageRef = storage.reference().child("profile_images/\(uid).jpg")
            
            do {
                let url = try await storageRef.downloadURL()
                let (imageData, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: imageData) {
                    await MainActor.run {
                        self.profileImage = uiImage
                    }
                }
            } catch {
                // If no custom profile image, use default system image
                print("No custom profile image found, using default: \(error.localizedDescription)")
            }
        }
    }
}
