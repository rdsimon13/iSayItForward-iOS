import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MySIFsView: View {
    @State private var sifs: [SIFItem] = []

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    self.appGradientTopOnly()

                    VStack {
                        if sifs.isEmpty {
                            Text("You haven't sent any SIFs yet!")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            List(sifs) { sif in
                                NavigationLink(destination: SIFDetailView(sif: sif)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(sif.subject)
                                                .font(.headline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            if sif.signatureImageData != nil {
                                                Image(systemName: "signature")
                                                    .font(.caption)
                                                    .foregroundColor(Color.brandDarkBlue)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(Color.brandDarkBlue.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            }
                                        }
                                        Text("To: \(sif.recipients.joined(separator: ", "))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Scheduled for: \(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .navigationTitle("Manage My SIFs")
                    .onAppear {
                        fetchSIFs()
                    }
                }
            }
        } else {
            Text("This feature requires iOS 16.0 or newer.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

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

struct MySIFsView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                MySIFsView()
            }
        } else {
            Text("Preview not available below iOS 16.")
        }
    }
}
