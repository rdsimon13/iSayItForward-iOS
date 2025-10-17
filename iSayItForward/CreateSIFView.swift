import SwiftUI

struct CreateSIFView: View {
    @State private var recipientEmail: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var scheduleForLater: Bool = false
    @State private var selectedTab = "Single"
    
    // ✅ Signature integration
    @State private var showSignatureView = false
    @State private var savedSignature: SignatureData? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.75, green: 0.92, blue: 1.0),
                        Color(red: 0.60, green: 0.85, blue: 0.98)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Header Tabs (Single / Multiple / Group)
                        HeaderTabs(selectedTab: $selectedTab)

                        // MARK: - Recipient Fields
                        RecipientFields(recipientEmail: $recipientEmail, subject: $subject)

                        // MARK: - Message Field
                        MessageField(message: $message)

                        // MARK: - Schedule Toggle
                        ScheduleToggle(scheduleForLater: $scheduleForLater)

                        // MARK: - Enhancement Section + Signature Sheet
                        EnhancementSection(showSignatureView: $showSignatureView)

                        // ✅ Signature Preview (appears after save)
                        if let signature = savedSignature {
                            SignaturePreviewView(signatureData: signature)
                                .padding(.horizontal)
                        }

                        // MARK: - Send Button
                        PrimaryActionButton(
                            title: "Send SIF",
                            gradientColors: [
                                Color(red: 1.0, green: 0.8, blue: 0.0),
                                Color(red: 1.0, green: 0.65, blue: 0.0)
                            ],
                            action: sendSIF
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Create a SIF")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ Present Signature View
            .sheet(isPresented: $showSignatureView) {
                SignatureView(isPresented: $showSignatureView) { signature in
                    savedSignature = signature
                    print("✅ Signature saved for user: \(signature.userUID)")
                }
            }
        }
    }

    // MARK: - Send SIF Action
    private func sendSIF() {
        print("📨 Sending SIF to: \(recipientEmail), subject: \(subject)")
        if let signature = savedSignature {
            print("🖋️ Signature attached from: \(signature.userUID)")
        }
    }
}

// MARK: - Header Tabs
private struct HeaderTabs: View {
    @Binding var selectedTab: String
    let tabs = ["Single", "Multiple", "Group"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.white : Color.white.opacity(0.3))
                                .shadow(
                                    color: selectedTab == tab ? .black.opacity(0.15) : .clear,
                                    radius: 3,
                                    y: 2
                                )
                        )
                        .foregroundColor(selectedTab == tab ? .black : .gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Recipient Fields
private struct RecipientFields: View {
    @Binding var recipientEmail: String
    @Binding var subject: String

    var body: some View {
        VStack(spacing: 14) {
            CapsuleField(placeholder: "Recipient’s Email", text: $recipientEmail, secure: false)
            CapsuleField(placeholder: "Subject", text: $subject, secure: false)
        }
        .padding(.horizontal)
    }
}

// MARK: - Message Field
private struct MessageField: View {
    @Binding var message: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            TextEditor(text: $message)
                .scrollContentBackground(.hidden)
                .padding()
                .frame(minHeight: 140)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.black)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.2))
                )

            if message.isEmpty {
                Text("Write your message here...")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Schedule Toggle
private struct ScheduleToggle: View {
    @Binding var scheduleForLater: Bool

    var body: some View {
        HStack {
            Text("Schedule for later")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.75))

            Spacer()

            Toggle("", isOn: $scheduleForLater)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Enhancement Section
private struct EnhancementSection: View {
    @Binding var showSignatureView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENHANCE YOUR SIF!")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                .padding(.horizontal)

            HStack(spacing: 16) {
                EnhancementButton(title: "Templates", systemIcon: "doc.on.doc") {}
                EnhancementButton(title: "Upload", systemIcon: "square.and.arrow.up") {}
                EnhancementButton(title: "Signature", systemIcon: "signature") {
                    showSignatureView = true
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Enhancement Button
private struct EnhancementButton: View {
    let title: String
    let systemIcon: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: systemIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Color.blue)
                }
                .frame(width: 80, height: 60)
                .background(Color.white.opacity(0.9))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}
