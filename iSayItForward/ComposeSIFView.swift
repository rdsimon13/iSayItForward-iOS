import SwiftUI

struct ComposeSIFView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @Environment(\.appRoute) private var appRoute

    @State private var message: String = ""
    @State private var tone: String = "Supportive"
    @State private var emotion: String = "Joyful"
    @State private var isEnhanced = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background (Global Welcome Gradient)
                GradientTheme.welcomeBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        Spacer(minLength: 40)

                        // MARK: - Header
                        VStack(spacing: 14) {
                            Image("isiFLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 90)
                                .rotationEffect(.degrees(2))
                                .offset(x: 2)
                                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                            OutlinedText(
                                text: "iSayItForward",
                                font: TextStyles.title(36),
                                fillColor: Color(red: 0.9, green: 0.96, blue: 0.96),
                                strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                                outlineWidth: 0.8,
                                shadowColor: .black,
                                shadowRadius: 3,
                                tracking: 1.5
                            )

                            OutlinedText(
                                text: "Welcome to the SIF Composer\n& Compose Your SIF Below",
                                font: TextStyles.subtitle(16),
                                fillColor: Color(red: 0.9, green: 0.96, blue: 0.96),
                                strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                                outlineWidth: 0.6,
                                shadowColor: .black,
                                shadowRadius: 2,
                                tracking: 1.3
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 2)
                        }

                        // MARK: - Text Input Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Enhance Your SIF")
                                .font(TextStyles.subtitle(18))
                                .foregroundColor(Color.black.opacity(0.8))
                                .tracking(1.3)
                                .padding(.horizontal, 8)

                            TextEditor(text: $message)
                                .padding()
                                .frame(minHeight: 160)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.95))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22)
                                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .font(TextStyles.body(15))
                                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                                .padding(.horizontal, 30)
                        }

                        // MARK: - Tone and Emotion Buttons
                        VStack(spacing: 18) {
                            HStack(spacing: 16) {
                                selectButton(title: "Supportive", selected: tone == "Supportive") {
                                    tone = "Supportive"
                                }
                                selectButton(title: "Motivational", selected: tone == "Motivational") {
                                    tone = "Motivational"
                                }
                            }

                            HStack(spacing: 16) {
                                selectButton(title: "Joyful", selected: emotion == "Joyful") {
                                    emotion = "Joyful"
                                }
                                selectButton(title: "Calm", selected: emotion == "Calm") {
                                    emotion = "Calm"
                                }
                            }
                        }

                        // MARK: - Send Button
                        VStack(spacing: 16) {
                            Button(action: deliverSIF) {
                                Text("Deliver Your SIF")
                                    .font(TextStyles.subtitle(18))
                                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.05))
                                    .tracking(1.3)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(GradientTheme.goldPill)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
                            }
                            .padding(.horizontal, 50)

                            Button("Let’s Send My SIF") {
                                print("📨 Sending flow triggered")
                            }
                            .font(TextStyles.body(15))
                            .foregroundColor(Color(red: 0.12, green: 0.22, blue: 0.32))
                            .tracking(1)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("SIF Composer", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Selectable Capsule Buttons
    private func selectButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(TextStyles.body(15))
                .tracking(1.2)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(
                            selected
                                ? GradientTheme.primaryPill
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                )
                .foregroundColor(selected ? .white : Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Deliver SIF Action (with delay enhancement)
    private func deliverSIF() {
        guard !message.isEmpty else {
            alertMessage = "Please compose your SIF before sending."
            showingAlert = true
            return
        }

        alertMessage = "🎉 Your SIF has been composed successfully!"
        showingAlert = true

        // ✅ Animated transition to confirm screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                appRoute?.wrappedValue = .confirm
            }
            message = ""
        }
    }
}

#Preview {
    ComposeSIFView()
        .environmentObject(AuthState())
}
