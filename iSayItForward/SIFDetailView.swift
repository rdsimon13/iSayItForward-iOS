import SwiftUI

struct SIFDetailView: View {
    let sif: SIFItem
    @State private var showingResponseComposer = false
    @State private var showingResponseList = false

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
                    
                    // Response Actions Section
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: {
                                showingResponseComposer = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.bubble")
                                    Text("Compose Response")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showingResponseList = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                    Text("View Responses")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        
                        NavigationLink(destination: ImpactMetricsView()) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                Text("View Impact Analytics")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(.white.opacity(0.85))
                            .foregroundColor(Color.brandDarkBlue)
                            .cornerRadius(10)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SIF Details")
        }
        .foregroundColor(Color.brandDarkBlue)
        .sheet(isPresented: $showingResponseComposer) {
            ResponseComposerView(
                sifItem: sif,
                onResponseSubmitted: {
                    showingResponseComposer = false
                    // Could trigger a refresh or show success message
                },
                onCancel: {
                    showingResponseComposer = false
                }
            )
        }
        .sheet(isPresented: $showingResponseList) {
            ResponseListView(sifId: sif.id)
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
