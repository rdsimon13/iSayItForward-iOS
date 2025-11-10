//
//  ComposeSIFView 2.swift
//  iSIF_Beta
//
//  Created by Reginald Simon on 11/5/25.
//


//
//  ComposeSIFView.swift
//  iSIF_Beta
//
//  Created by Reginald Simon on 11/5/25.
//

import SwiftUI
import FirebaseAuth

struct ComposeSIFView: View {
    // MARK: - Environment
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    // MARK: - State
    @State private var message: String = ""
    @State private var tone: String = "Friendly"
    @State private var emotion: String = "Joyful"
    @State private var deliveryType: String = "One-to-One"
    @State private var selectedFriends: [SIFRecipient] = []
    @State private var isScheduled = false
    @State private var scheduledDate = Date().addingTimeInterval(3600)
    @State private var isSending = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // MARK: - Service
    private let sifManager = SIFDataManager()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white, Color.blue.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Compose a SIF")
                    .font(.custom("AvenirNext-Bold", size: 26))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    TextField("Enter your message...", text: $message, axis: .vertical)
                        .lineLimit(4...8)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                        .padding(.horizontal, 20)

                    Toggle("Schedule for later", isOn: $isScheduled)
                        .padding(.horizontal, 20)

                    if isScheduled {
                        DatePicker(
                            "Send on:",
                            selection: $scheduledDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .padding(.horizontal, 20)
                    }

                    Picker("Tone", selection: $tone) {
                        Text("Friendly").tag("Friendly")
                        Text("Supportive").tag("Supportive")
                        Text("Professional").tag("Professional")
                        Text("Playful").tag("Playful")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)

                    Picker("Emotion", selection: $emotion) {
                        Text("Joyful").tag("Joyful")
                        Text("Calm").tag("Calm")
                        Text("Excited").tag("Excited")
                        Text("Reflective").tag("Reflective")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                }

                Spacer()

                Button(action: {
                    Task { await sendSIF() }
                }) {
                    Text(isSending ? "Sending..." : "Send SIF")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSending ? Color.gray : Color.blue)
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal, 40)
                }
                .disabled(isSending)
                .alert("SIF Status", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }

                Spacer()
            }
        }
    }

    // MARK: - Send SIF Logic
    private func sendSIF() async {
        guard !message.isEmpty else {
            alertMessage = "Please enter a message before sending."
            showingAlert = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to send a SIF."
            showingAlert = true
            return
        }

        isSending = true
        print("🚀 Sending SIF for user \(userId)")

        do {
            // Generate recipient (placeholder for demo)
            let recipients = selectedFriends.isEmpty
                ? [SIFRecipient(name: "John Demo", email: "john@example.com")]
                : selectedFriends

            // Construct SIF
            let sif = SIF(
                senderId: userId,
                recipients: recipients,
                subject: "My SIF",
                message: message,
                category: "General",
                tone: tone,
                emotion: emotion,
                templateId: nil,
                documentURL: nil,
                deliveryType: deliveryType,
                isScheduled: isScheduled,
                scheduledDate: isScheduled ? scheduledDate : nil,
                createdAt: Date(),
                status: isScheduled ? "scheduled" : "sent"
            )

            // Save to Firestore
            try await sifManager.sendSIF(sif, for: userId)

            isSending = false
            alertMessage = "✅ Your SIF has been sent successfully!"
            showingAlert = true

            // Optional: Navigate to confirmation view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                router.selectedTab = .profile
            }

        } catch {
            print("❌ Failed to send SIF: \(error.localizedDescription)")
            alertMessage = "Failed to send your SIF. Please try again."
            showingAlert = true
            isSending = false
        }
    }
}

// MARK: - Preview
#Preview {
    ComposeSIFView()
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}