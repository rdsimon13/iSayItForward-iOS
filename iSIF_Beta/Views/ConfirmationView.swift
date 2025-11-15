//
//  SIFConfirmationView.swift
//  iSIF_Beta
//

import SwiftUI

struct SIFConfirmationView: View {
    @EnvironmentObject var router: TabRouter
    let sif: SIF

    @State private var animateSuccess = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.green.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Success Checkmark Animation
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .foregroundColor(.green)
                    .scaleEffect(animateSuccess ? 1.1 : 0.7)
                    .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateSuccess)
                    .onAppear { animateSuccess = true }

                // Header
                Text("SIF Sent Successfully! 🎉")
                    .font(.custom("AvenirNext-DemiBold", size: 24))
                    .foregroundColor(Color(hex: "132E37"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Summary Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recipient:")
                            .font(.custom("AvenirNext-DemiBold", size: 15))
                        Spacer()
                        Text(sif.recipients.first?.name ?? "Unknown")
                            .font(.custom("AvenirNext-Regular", size: 15))
                    }
                    Divider()

                    HStack(alignment: .top) {
                        Text("Message:")
                            .font(.custom("AvenirNext-DemiBold", size: 15))
                        Spacer()
                        Text(sif.message)
                            .font(.custom("AvenirNext-Regular", size: 15))
                            .lineLimit(3)
                    }
                    Divider()

                    HStack {
                        Text("Delivery:")
                            .font(.custom("AvenirNext-DemiBold", size: 15))
                        Spacer()
                        Text(sif.deliveryType.displayTitle)
                            .font(.custom("AvenirNext-Regular", size: 15))
                    }

                    if let when = sif.deliveryDate
                    {
                        Divider()
                        HStack {
                            Text("Scheduled For:")
                                .font(.custom("AvenirNext-DemiBold", size: 15))
                            Spacer()
                            Text(when.formatted(date: .abbreviated, time: .shortened))
                                .font(.custom("AvenirNext-Regular", size: 15))
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.95)))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                .padding(.horizontal, 30)

                Spacer()

                // Back to Inbox (Home tab)
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) { fadeOut = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        router.selectedTab = .home
                    }
                } label: {
                    Text("📬 Back to Inbox")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        )
                        .padding(.horizontal, 60)
                        .opacity(fadeOut ? 0.4 : 1)
                }
                .padding(.bottom, 40)
            }
            .padding(.top, 100)
        }
        .navigationBarBackButtonHidden(true)
    }
}
