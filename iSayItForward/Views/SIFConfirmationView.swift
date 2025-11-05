import SwiftUI

struct SIFConfirmationView: View {
    @EnvironmentObject var router: TabRouter
    let sif: SIF
    
    @State private var animateSuccess = false
    
    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.green)
                    .scaleEffect(animateSuccess ? 1.1 : 0.8)
                    .animation(.easeInOut(duration: 0.7).repeatCount(2, autoreverses: true), value: animateSuccess)
                    .onAppear { animateSuccess = true }
                
                Text("SIF Sent Successfully! 🎉")
                    .font(.custom("AvenirNext-DemiBold", size: 22))
                    .foregroundColor(Color(hex: "132E37"))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipient: \(sif.recipients.first?.name ?? "Unknown")")
                    Text("Message: “\(sif.message)”")
                    Text("Tone: \(sif.tone ?? "None")")
                    Text("Emotion: \(sif.emotion ?? "None")")
                }
                .font(.custom("AvenirNext-Regular", size: 15))
                .padding()
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.9)))
                .shadow(radius: 3)
                
                Button {
                    withAnimation { router.selectedTab = .profile }
                } label: {
                    Text("📬 Back to Inbox")
                        .font(.custom("AvenirNext-DemiBold", size: 17))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.green))
                }
                .padding(.horizontal, 40)
            }
            .padding(.top, 80)
        }
        .navigationBarBackButtonHidden(true)
    }
}
#Preview {
    let demoSIF = SIF(
        senderId: "12345",
        recipients: [SIFRecipient(name: "John Doe", email: "john@example.com")],
        subject: "A Test SIF",
        message: "Here’s a warm message from your future self.",
        category: "General",
        tone: "Supportive",
        emotion: "Joyful",
        templateId: nil,
        documentURL: nil,
        deliveryType: "One-to-One",
        isScheduled: true,
        scheduledDate: Date().addingTimeInterval(86400),
        createdAt: Date(),
        status: "sent"
    )
    
    return SIFConfirmationView(sif: demoSIF)
        .environmentObject(TabRouter())
}
