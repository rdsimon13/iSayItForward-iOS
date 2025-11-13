//
// SIFConfirmationView.swift
//  iSIF_Beta
//
//  Created by Reginald Simon on 11/5/25.
//
/*
import SwiftUI

struct SIFConfirmationView: View {
    @EnvironmentObject var router: TabRouter
    let sif: SIF
    
    @State private var animateSuccess = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.95, blue: 1.0),
                    Color(red: 0.65, green: 0.85, blue: 0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // MARK: - Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                    .scaleEffect(animateSuccess ? 1.1 : 0.8)
                    .animation(.easeInOut(duration: 0.7).repeatCount(2, autoreverses: true), value: animateSuccess)
                    .onAppear {
                        animateSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showConfetti = true
                        }
                    }
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                
                // MARK: - Confirmation Title
                Text("SIF Sent Successfully! 🎉")
                    .font(.custom("AvenirNext-DemiBold", size: 24))
                    .foregroundColor(Color(hex: "132E37"))
                    .padding(.top, 10)
                
                // MARK: - Message Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipient: \(sif.recipients.first?.name ?? "Unknown")")
                    Text("Message: “\(sif.message)”")
                    Text("Subject: \(sif.subject ?? "No Subject")")
                    Text("Delivery: \(sif.deliveryType.displayTitle)")
                    Text("Status: \(sif.status.capitalized)")
                }
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.black.opacity(0.8))
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                )
                .padding(.horizontal, 30)
                
                // MARK: - Back Button
                Button {
                    withAnimation {
                        router.selectedTab = .profile
                    }
                } label: {
                    Text("📬 Back to Inbox")
                        .font(.custom("AvenirNext-DemiBold", size: 17))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.green))
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                }
                .padding(.horizontal, 40)
            }
            .padding(.top, 80)
            
            // MARK: - Confetti Layer
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettis: [ConfettiPiece] = []
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let emojis = ["🎉", "🎊", "💫", "✨", "🎈", "🥳"]
    
    var body: some View {
        GeometryReader { geo in
            ForEach(confettis) { confetti in
                Text(confetti.emoji)
                    .font(.system(size: confetti.size))
                    .position(x: confetti.x, y: confetti.y)
                    .rotationEffect(.degrees(confetti.rotation))
                    .opacity(confetti.opacity)
            }
            .onAppear {
                for _ in 0..<25 {
                    let newConfetti = ConfettiPiece(
                        emoji: emojis.randomElement()!,
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: -50...0),
                        rotation: Double.random(in: 0...360),
                        opacity: Double.random(in: 0.8...1.0),
                        size: CGFloat.random(in: 18...30)
                    )
                    confettis.append(newConfetti)
                }
                animate(in: geo.size)
            }
        }
        .ignoresSafeArea()
    }
    
    func animate(in size: CGSize) {
        withAnimation(.easeInOut(duration: 3.5)) {
            for i in 0..<confettis.count {
                confettis[i].y = size.height + 100
                confettis[i].rotation += Double.random(in: 180...720)
                confettis[i].opacity = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            confettis.removeAll()
        }
    }
}

// MARK: - Confetti Model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var emoji: String
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
    var size: CGFloat
}

// MARK: - Preview
#Preview {
    let demoSIF = SIF(
        senderUID: "12345",
        recipients: [SIFRecipient(name: "John Doe", email: "john@example.com")],
        subject: "A Test SIF",
        message: "Here’s a warm message from your future self.",
        deliveryType: .oneToOne,
        scheduledAt: Date().addingTimeInterval(86400),
        createdAt: Date(),
        status: "sent"
    )
    
    let tabRouter = TabRouter()
    
    return SIFConfirmationView(sif: demoSIF)
        .environmentObject(tabRouter)
}
*/
