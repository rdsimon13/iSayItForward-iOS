import SwiftUI

struct SharedProfileActionSheet: View {
    let profile: UserProfile
    let shareURL: URL?
    let shareText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Header
            VStack(spacing: 8) {
                Text("Share Profile")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.brandDarkBlue)
                
                Text("Share \(profile.name)'s profile with others")
                    .font(.subheadline)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            
            // Share options
            VStack(spacing: 16) {
                ShareOptionButton(
                    icon: "message.fill",
                    title: "Messages",
                    subtitle: "Share via Messages app",
                    color: .green
                ) {
                    shareViaMessages()
                }
                
                ShareOptionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    subtitle: "Share via Email",
                    color: .blue
                ) {
                    shareViaEmail()
                }
                
                ShareOptionButton(
                    icon: "doc.on.doc.fill",
                    title: "Copy Link",
                    subtitle: "Copy profile link to clipboard",
                    color: Color.brandYellow
                ) {
                    copyToClipboard()
                }
                
                ShareOptionButton(
                    icon: "square.and.arrow.up.fill",
                    title: "More Options",
                    subtitle: "Share via other apps",
                    color: Color.brandDarkBlue
                ) {
                    showSystemShareSheet()
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 32)
            
            // Cancel button
            Button("Cancel") {
                isPresented = false
            }
            .font(.headline)
            .foregroundColor(Color.brandDarkBlue)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.brandDarkBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
    
    private func shareViaMessages() {
        guard let url = shareURL else { return }
        let messageURL = URL(string: "sms:?body=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let messageURL = messageURL, UIApplication.shared.canOpenURL(messageURL) {
            UIApplication.shared.open(messageURL)
        }
        
        isPresented = false
    }
    
    private func shareViaEmail() {
        guard let url = shareURL else { return }
        let subject = "Check out this profile on iSayItForward"
        let body = "\(shareText)\n\n\(url.absoluteString)"
        
        let emailURL = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let emailURL = emailURL, UIApplication.shared.canOpenURL(emailURL) {
            UIApplication.shared.open(emailURL)
        }
        
        isPresented = false
    }
    
    private func copyToClipboard() {
        if let url = shareURL {
            UIPasteboard.general.string = "\(shareText)\n\n\(url.absoluteString)"
        } else {
            UIPasteboard.general.string = shareText
        }
        
        // You could show a toast notification here
        isPresented = false
    }
    
    private func showSystemShareSheet() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            isPresented = false
            return
        }
        
        var items: [Any] = [shareText]
        if let url = shareURL {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        window.rootViewController?.present(activityVC, animated: true)
        isPresented = false
    }
}

struct ShareOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue.opacity(0.4))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Report User Action Sheet

struct ReportUserActionSheet: View {
    let profile: UserProfile
    @Binding var isPresented: Bool
    let onReport: (String, String) -> Void
    
    @State private var selectedReason: ReportReason = .spam
    @State private var details: String = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Report User")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text("Help us keep the community safe by reporting inappropriate behavior.")
                        .font(.subheadline)
                        .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Reason picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reason for reporting")
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    VStack(spacing: 8) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            ReasonOptionView(
                                reason: reason,
                                isSelected: selectedReason == reason
                            ) {
                                selectedReason = reason
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Additional details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional details (optional)")
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    TextEditor(text: $details)
                        .frame(height: 100)
                        .padding(12)
                        .background(Color.brandDarkBlue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brandDarkBlue.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Submit Report") {
                        showingConfirmation = true
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .padding(.horizontal)
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(Color.brandDarkBlue)
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .background(Color.mainAppGradient.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .alert("Confirm Report", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                onReport(selectedReason.rawValue, details)
                isPresented = false
            }
        } message: {
            Text("Are you sure you want to report \(profile.name) for \(selectedReason.rawValue.lowercased())? This action cannot be undone.")
        }
    }
}

struct ReasonOptionView: View {
    let reason: ReportReason
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color.brandYellow : Color.brandDarkBlue.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(reason.description)
                        .font(.caption)
                        .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.brandYellow.opacity(0.1) : Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandYellow : Color.brandDarkBlue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct SharedProfileActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            SharedProfileActionSheet(
                profile: sampleProfile,
                shareURL: URL(string: "https://isayitforward.app/profile/123"),
                shareText: "Check out John Doe's profile on iSayItForward!",
                isPresented: .constant(true)
            )
        }
        .background(Color.black.opacity(0.3))
        .preferredColorScheme(.light)
    }
    
    static let sampleProfile = UserProfile(
        uid: "123",
        name: "John Doe",
        email: "john@example.com",
        bio: "Spreading kindness one SIF at a time!",
        profileImageURL: nil,
        joinDate: Date(),
        followersCount: 42,
        followingCount: 28,
        sifsSharedCount: 156,
        totalImpactScore: 2340
    )
}