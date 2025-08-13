import SwiftUI

struct GettingStartedView: View {
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
                            GettingStartedCard(
                                stepNumber: 1,
                                title: "Create Your First SIF",
                                description: "Start by creating a personalized message with our easy-to-use composer.",
                                iconName: "square.and.pencil"
                            )
                            
                            GettingStartedCard(
                                stepNumber: 2,
                                title: "Add Your Signature",
                                description: "Enhance your SIFs with a digital signature for a personal touch.",
                                iconName: "signature"
                            )
                            
                            GettingStartedCard(
                                stepNumber: 3,
                                title: "Choose Templates",
                                description: "Browse our template gallery for quick and beautiful message templates.",
                                iconName: "doc.on.doc"
                            )
                            
                            GettingStartedCard(
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
                                NavigationLink(destination: CreateSIFView()) {
                                    QuickActionButton(iconName: "square.and.pencil", text: "Create SIF")
                                }
                                
                                NavigationLink(destination: TemplateGalleryView()) {
                                    QuickActionButton(iconName: "doc.on.doc", text: "Templates")
                                }
                                
                                NavigationLink(destination: ProfileView()) {
                                    QuickActionButton(iconName: "person.crop.circle", text: "Profile")
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
        }
    }
}

// MARK: - Getting Started Card
private struct GettingStartedCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
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
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let iconName: String
    let text: String
    
    var body: some View {
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

struct GettingStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GettingStartedView()
    }
}
