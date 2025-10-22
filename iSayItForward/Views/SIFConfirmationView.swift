import SwiftUI

struct SIFConfirmView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var showingSuccess = false
    @State private var showingAlert = false

    // Mock example of what user just composed
    @State private var sifMessage: String = """
    I just wanted to say thank you for always showing up with kindness and authenticity.
    The way you share your energy inspires everyone around you.
    Keep shining forward 🌟
    """

    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground

            VStack(spacing: 36) {
                Spacer(minLength: 50)

                // MARK: - Header
                VStack(spacing: 14) {
                    Image("isiFLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 85)
                        .rotationEffect(.degrees(2))
                        .offset(x: 2)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                    OutlinedText(
                        text: "Your SIF is Ready!",
                        font: TextStyles.title(34),
                        fillColor: Color(red: 0.9, green: 0.96, blue: 0.96),
                        strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                        outlineWidth: 0.8,
                        shadowColor: Color.black,
                        shadowRadius: 4,
                        tracking: 1.8
                    )

                    OutlinedText(
                        text: "Here’s your message preview before delivery",
                        font: TextStyles.subtitle(17),
                        fillColor: Color(red: 0.9, green: 0.96, blue: 0.96),
                        strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                        outlineWidth: 0.6,
                        shadowColor: .black,
                        shadowRadius: 2,
                        tracking: 1.4
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }

                // MARK: - Message Preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("SIF Preview")
                        .font(TextStyles.subtitle(18))
                        .foregroundColor(Color.black.opacity(0.8))
                        .tracking(1.2)

                    ScrollView {
                        Text(sifMessage)
                            .font(TextStyles.body(16))
                            .foregroundColor(Color.black.opacity(0.8))
                            .tracking(0.8)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                            .padding(.bottom, 6)
                    }
                    .frame(maxHeight: 220)
                }
                .padding(.horizontal, 40)

                // MARK: - Action Buttons
                VStack(spacing: 18) {
                    Button(action: {
                        showingSuccess = true
                    }) {
                        Text("Deliver Now")
                            .font(TextStyles.subtitle(18))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.05))
                            .tracking(1.3)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(GradientTheme.goldPill)
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
                    }
                    .padding(.horizontal, 60)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Edit My SIF")
                            .font(TextStyles.body(16))
                            .foregroundColor(.black.opacity(0.8))
                            .tracking(1)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.95))
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                    }
                    .padding(.horizontal, 80)
                }

                Spacer()

                // MARK: - Bottom Branding
                Text("Delivering Kindness, One Message at a Time.")
                    .font(TextStyles.small(12))
                    .foregroundColor(Color.black.opacity(0.65))
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
        .alert("🎉 Success!", isPresented: $showingSuccess) {
            Button("OK") {}
        } message: {
            Text("Your SIF has been sent successfully.")
        }
    }
}

#Preview {
    SIFConfirmView()
        .environmentObject(AuthState())
}
