import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @Binding var selectedTab: Int
    @State private var userName: String = "User"
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.70, green: 0.90, blue: 1.0),
                        Color(red: 0.55, green: 0.75, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 26) {
                    Spacer(minLength: 20)
                    
                    // MARK: - Header
                    VStack(spacing: 6) {
                        Image("isiFLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 85)
                            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                        
                        Text("iSayItForward")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.08, green: 0.15, blue: 0.3))
                        
                        Text("The Ultimate Way to Express Yourself")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.12, green: 0.22, blue: 0.32))
                    }
                    
                    // MARK: - Welcome Bubble
                    Text("Welcome to iSIF, \(userName).")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                        )
                    
                    // MARK: - Main Buttons
                    HStack(spacing: 28) {
                        VStack(spacing: 6) {
                            Button {
                                selectedTab = 4 // Navigate to Getting Started tab
                            } label: {
                                CircleIconButton(icon: "figure.walk", color: .indigo)
                            }
                            Text("Getting Started")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        VStack(spacing: 6) {
                            Button {
                                selectedTab = 1 // Create a SIF
                            } label: {
                                CircleIconButton(icon: "square.and.pencil", color: .blue)
                            }
                            Text("CREATE A SIF")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        
                        VStack(spacing: 6) {
                            Button {
                                selectedTab = 3 // Manage SIFs (Schedule)
                            } label: {
                                CircleIconButton(icon: "envelope.fill", color: .teal)
                            }
                            Text("MANAGE MY SIF'S")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                        }
                    }
                    
                    // MARK: - Info Cards
                    VStack(spacing: 16) {
                        Button {
                            selectedTab = 2 // Template Gallery
                        } label: {
                            InfoCard(
                                title: "SIF Template Gallery",
                                subtitle: "Explore a variety of ready-made templates to express yourself with style and speed.",
                                trailingSystemIcon: "photo.on.rectangle"
                            )
                        }
                        
                        Button {
                            selectedTab = 3 // Schedule tab
                        } label: {
                            InfoCard(
                                title: "Schedule a SIF",
                                subtitle: "Never forget to send greetings on that special day. Schedule your SIF for future delivery!",
                                trailingSystemIcon: "calendar"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // MARK: - Logout Button
                    Button(action: signOut) {
                        Label("Log Out", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(Color(red: 0.12, green: 0.25, blue: 0.45))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                if let user = Auth.auth().currentUser {
                    userName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
                }
            }
        }
    }
    
    // MARK: - Functions
    private func signOut() {
        do {
            try Auth.auth().signOut()
            authState.isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reusable Subviews

struct CircleIconButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(Circle().fill(color))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
    }
}
