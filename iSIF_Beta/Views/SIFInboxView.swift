//
//  SIFInboxView.swift
//  iSIF_Beta
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Inbox with Sent / Received tabs
struct SIFInboxView: View {
    @State private var sentSIFs: [SIF] = []
    @State private var receivedSIFs: [SIF] = []
    @State private var error: Error?
    @State private var loading = false

    var body: some View {
        TabView {
            SentView(sentSIFs: sentSIFs, error: $error)
                .tabItem { Label("Sent", systemImage: "paperplane.fill") }

            ReceivedView(receivedSIFs: receivedSIFs, error: $error)
                .tabItem { Label("Received", systemImage: "tray.fill") }
        }
        .onAppear {
            fetchSentSIFs()
            fetchReceivedSIFs()
        }
    }

    // MARK: - Firestore Loads

    /// Fetches all SIFs sent by the current user
    private func fetchSentSIFs() {
        loading = true
        guard let uid = Auth.auth().currentUser?.uid else {
            loading = false
            return
        }

        Firestore.firestore().collection("SIFs")  // ✅ Corrected: Firestore collection name is case-sensitive
            .whereField("senderUID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, err in
                loading = false
                if let err = err {
                    self.error = err
                    return
                }

                // ✅ Firestore Codable decoding
                let items = snap?.documents.compactMap { doc in
                    try? doc.data(as: SIF.self)
                } ?? []

                print("📬 Loaded Sent SIFs: \(items.count)")
                self.sentSIFs = items
            }
    }

    /// Fetches all SIFs received by the current user
    private func fetchReceivedSIFs() {
        loading = true

        guard let currentEmail = Auth.auth().currentUser?.email?.lowercased() else {
            loading = false
            receivedSIFs = []
            return
        }

        let q = Firestore.firestore().collection("SIFs")  // ✅ Corrected capitalization
            .whereField("status", isEqualTo: "sent")

        q.getDocuments { snap, err in
            self.loading = false
            if let err = err {
                self.error = err
                return
            }

            // ✅ Decode all and filter client-side by recipient email
            let all = snap?.documents.compactMap { doc in
                try? doc.data(as: SIF.self)
            } ?? []

            let filtered = all.filter { sif in
                sif.recipients.contains { recipient in
                    recipient.email.lowercased() == currentEmail
                }
            }

            print("📥 Loaded Received SIFs: \(filtered.count)")
            self.receivedSIFs = filtered
        }
    }
}

// MARK: - Sent / Received Subviews

private struct SentView: View {
    var sentSIFs: [SIF]
    @Binding var error: Error?

    var body: some View {
        if let error {
            ErrorView(error: error)
        } else if sentSIFs.isEmpty {
            EmptyStateView(text: "No sent SIFs yet.")
        } else {
            List(sentSIFs) { sif in
                VStack(alignment: .leading, spacing: 6) {
                    Text(sif.subject ?? "No Subject")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(sif.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text("📤 \(sif.deliveryType.displayTitle)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(sif.status.capitalized)
                            .font(.caption)
                            .foregroundColor(sif.status.lowercased() == "sent" ? .green : .gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ReceivedView: View {
    var receivedSIFs: [SIF]
    @Binding var error: Error?

    var body: some View {
        if let error {
            ErrorView(error: error)
        } else if receivedSIFs.isEmpty {
            EmptyStateView(text: "No received SIFs yet.")
        } else {
            List(receivedSIFs) { sif in
                VStack(alignment: .leading, spacing: 6) {
                    Text(sif.recipients.first?.name ?? "Unknown Sender")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(sif.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text("📬 \(sif.deliveryType.displayTitle)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ErrorView: View {
    var error: Error
    var body: some View {
        VStack(spacing: 12) {
            Text("An error occurred:")
                .font(.headline)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Retry") { /* Optional retry logic */ }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
        }
        .padding()
    }
}

private struct EmptyStateView: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding()
    }
}
