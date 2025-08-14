import SwiftUI
import Firebase

struct GettingStartedView: View {
    // Add environment objects for Firebase integration
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var matchDataState: MatchDataState
    
    var body: some View {
        NavigationStack {
            ZStack {
                self.appGradientTopOnly()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Welcome Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Getting Started")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text("Learn how to make the most of iSayItForward")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                        
                        // Step Cards
                        VStack(spacing: 16) {
                            stepCard(
                                stepNumber: 1,
                                title: "Create Your First SIF",
                                description: "Start by creating a personalized message with our easy-to-use composer.",
                                iconName: "square.and.pencil"
                            )
                            
                            stepCard(
                                stepNumber: 2,
                                title: "Add Your Signature",
                                description: "Enhance your SIFs with a digital signature for a personal touch.",
                                iconName: "signature"
                            )
                            
                            stepCard(
                                stepNumber: 3,
                                title: "Choose Templates",
                                description: "Browse our template gallery for quick and beautiful message templates.",
                                iconName: "doc.on.doc"
                            )
                            
                            stepCard(
                                stepNumber: 4,
                                title: "Schedule Delivery",
                                description: "Never forget important dates - schedule your SIFs for future delivery.",
                                iconName: "calendar"
                            )
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            HStack(spacing: 12) {
                                NavigationLink(destination: Text("Create SIF View")) {
                                    quickActionButton(iconName: "square.and.pencil", text: "Create SIF")
                                }
                                
                                NavigationLink(destination: Text("Template Gallery View")) {
                                    quickActionButton(iconName: "doc.on.doc", text: "Templates")
                                }
                                
                                NavigationLink(destination: Text("Profile View")) {
                                    quickActionButton(iconName: "person.crop.circle", text: "Profile")
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("🟢 GettingStartedView.onAppear called")
                
                // Safe Firebase usage - wrapped in checks
                if FirebaseApp.app() != nil, let userId = authState.user?.uid {
                    print("📱 User logged in with ID: \(userId)")
                } else {
                    print("📱 No user logged in or Firebase not ready")
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Instead of using a separate struct, define it as a function that returns a view
    private func stepCard(stepNumber: Int, title: String, description: String, iconName: String) -> some View {
        HStack(spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Color.brandDarkBlue)
                    .frame(width: 40, height: 40)
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandDarkBlue)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
        }
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private func quickActionButton(iconName: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color.brandDarkBlue)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.brandDarkBlue)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
    }
}

// MARK: - Preview Provider
struct GettingStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GettingStartedView()
            .environmentObject(AuthState())
            .environmentObject(MatchDataState())
    }
}
