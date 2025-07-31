import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SIFDetailView: View {
    let sif: SIFItem
    @State private var showingUserProfile = false

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Detail Card for Key Information
                    VStack(alignment: .leading, spacing: 12) {
                        // Author row - only show if it's not the current user
                        if sif.authorUid != Auth.auth().currentUser?.uid {
                            AuthorRow(authorUid: sif.authorUid) {
                                showingUserProfile = true
                            }
                            Divider()
                        }
                        
                        DetailRow(icon: "person.2.fill", title: "Recipients", value: sif.recipients.joined(separator: ", "))
                        Divider()
                        DetailRow(icon: "calendar", title: "Scheduled For", value: sif.scheduledDate.formatted(date: .long, time: .shortened))
                        Divider()
                        DetailRow(icon: "paperplane.fill", title: "Subject", value: sif.subject)
                    }
                    .padding()
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Card for the Message Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(sif.message)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SIF Details")
        }
        .foregroundColor(Color.brandDarkBlue)
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(userUID: sif.authorUid)
        }
    }
}

// Helper view for a consistent row style in the detail card
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.body.weight(.semibold))
        }
    }
}

// Preview requires a sample SIFItem to work
struct SIFDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SIFDetailView(sif: SIFItem(authorUid: "123", recipients: ["preview@example.com"], subject: "Preview Subject", message: "This is a longer preview message to see how the text wraps and the card expands.", createdDate: Date(), scheduledDate: Date()))
        }
    }
}

// Author row component for showing author info
private struct AuthorRow: View {
    let authorUid: String
    let onTap: () -> Void
    @State private var authorName: String = "Loading..."
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                    Text("Author")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(authorName)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color.brandDarkBlue.opacity(0.6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadAuthorName()
        }
    }
    
    private func loadAuthorName() {
        // Simple Firebase query to get author name
        let db = Firestore.firestore()
        db.collection("users").document(authorUid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.authorName = document.data()?["name"] as? String ?? "Unknown User"
            } else {
                self.authorName = "Unknown User"
            }
        }
    }
}
