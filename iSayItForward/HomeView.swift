import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - HomeLaunchpadView must be defined first
private struct HomeLaunchpadView: View {
    @State private var userName: String = "User"

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Welcome to iSIF, \(userName).\nChoose an option below to get started.")
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    HStack(spacing: 16) {
                        NavigationLink(destination: Text("Getting Started Screen")) {
                            HomeActionButton(iconName: "figure.walk", text: "Getting Started")
                        }
                        NavigationLink(destination: SIFMessageComposerView()) {
                            HomeActionButton(iconName: "square.and.pencil", text: "CREATE A SIF")
                        }
                        NavigationLink(destination: MySIFsView()) {
                            HomeActionButton(iconName: "envelope", text: "MANAGE MY SIF'S")
                        }
                    }

                    NavigationLink(destination: TemplateGalleryView()) {
                        PromoCard(title: "SIF Template Gallery",
                                  description: "Explore a variety of ready made templates designed to help you express yourself with style and speed.",
                                  iconName: "photo.on.rectangle.angled")
                    }

                    NavigationLink(destination: SIFMessageComposerView()) {
                        PromoCard(title: "Schedule a SIF",
                                  description: "Never forget to send greetings on that special day ever again. Schedule your SIF for future delivery today!",
                                  iconName: "calendar")
                    }

                    Spacer()
                }
                .padding()
            }
            .onAppear(perform: fetchUserData)
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
    }

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.userName = document.data()?["name"] as? String ?? "User"
            }
        }
    }
}

private struct HomeActionButton: View {
    let iconName: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(Color.brandDarkBlue)
        .frame(maxWidth: .infinity)
    }
}

private struct PromoCard: View {
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.caption)
            }
            Spacer()
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .light))
        }
        .padding(20)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Main HomeView
struct HomeView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            TabView {
                NavigationStack {
                    HomeLaunchpadView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

                SIFMessageComposerView()
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Send SIF")
                    }

                TemplateGalleryView()
                    .tabItem {
                        Image(systemName: "doc.on.doc")
                        Text("Templates")
                    }

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
            }
            .accentColor(Color.brandDarkBlue)
        } else {
            Text("Home requires iOS 16.0 or newer.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.red)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
