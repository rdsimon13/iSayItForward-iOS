import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SIFDetailView: View {
    let sif: SIFItem
    @State private var showingReportSheet = false
    @State private var showingUserActionSheet = false
    @State private var authorName: String = "Unknown User"
    
    private var isOwnContent: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return currentUserId == sif.authorUid
    }

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Detail Card for Key Information
                    VStack(alignment: .leading, spacing: 12) {
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
            .toolbar {
                if !isOwnContent {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                showingReportSheet = true
                            }) {
                                Label("Report Content", systemImage: "flag")
                            }
                            
                            Button(action: {
                                showingUserActionSheet = true
                            }) {
                                Label("User Actions", systemImage: "person.crop.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Color.brandDarkBlue)
                        }
                    }
                }
            }
            .onAppear {
                fetchAuthorName()
            }
        }
        .foregroundColor(Color.brandDarkBlue)
        .sheet(isPresented: $showingReportSheet) {
            ReportContentView(
                contentId: sif.id ?? "",
                contentAuthorId: sif.authorUid
            )
        }
        .sheet(isPresented: $showingUserActionSheet) {
            UserActionSheet(
                userId: sif.authorUid,
                userName: authorName
            )
        }
    }
    
    private func fetchAuthorName() {
        let db = Firestore.firestore()
        db.collection("users").document(sif.authorUid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.authorName = document.data()?["name"] as? String ?? "Unknown User"
            }
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
