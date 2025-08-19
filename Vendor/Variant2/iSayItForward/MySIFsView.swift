import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MySIFsView: View {
    @State private var sifs: [SIFItem] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // FIXED: Use the new vibrant gradient
                Theme.vibrantGradient.ignoresSafeArea()

                VStack {
                    if sifs.isEmpty {
                        // --- Empty State View ---
                        VStack {
                            Spacer()
                            Image(systemName: "envelope.open")
                                .font(.system(size: 60))
                            Text("No SIFs Found")
                                .font(.title.weight(.bold))
                            Text("You haven't sent any SIFs yet!")
                                .font(.headline)
                            Spacer()
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        
                    } else {
                        // --- List of SIFs ---
                        List(sifs) { sif in
                            NavigationLink(destination: SIFDetailView(sif: sif)) {
                                SIFRowView(sif: sif)
                            }
                            // Apply styling to each row in the list
                            .listRowBackground(Color.clear) // Make the default row background transparent
                            .padding(.vertical, 8)
                            .frostedGlass()
                            .padding(.bottom, 8) // Add space between cards
                        }
                        .listStyle(.plain) // Use a plain list style for custom backgrounds
                        .scrollContentBackground(.hidden) // Makes the List background transparent
                    }
                }
                .navigationTitle("Manage My SIFs")
                .onAppear {
                    fetchSIFs()
                }
            }
        }
    }

    // Your original data fetching logic is 100% preserved.
    func fetchSIFs() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        let db = Firestore.firestore()
        db.collection("sifs").whereField("authorUid", isEqualTo: uid)
            .order(by: "createdDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching SIFs: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found.")
                    return
                }

                self.sifs = documents.compactMap { doc -> SIFItem? in
                    try? doc.data(as: SIFItem.self)
                }
            }
    }
}

// A new, reusable view for each row in the list to keep the main body clean
private struct SIFRowView: View {
    let sif: SIFItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(sif.subject)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("To: \(sif.recipients.joined(separator: ", "))")
                    .font(.subheadline)
                    .opacity(0.8)
                
                Text("Scheduled for: \(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .opacity(0.8)
            }
            
            Spacer()
            
            // Your original signature icon logic is preserved
            if sif.signatureImageData != nil {
                Image(systemName: "signature")
                    .font(.caption)
                    .foregroundColor(.white) // FIXED: Use white for readability
            }
        }
        .foregroundColor(.white) // Set the text color for the entire row
    }
}
