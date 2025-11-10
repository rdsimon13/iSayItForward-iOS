import SwiftUI

struct ReportOverlay: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    Text("📝 Report Issue")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("This is where your report UI could go — like a feedback form or flag system.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Close") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white))
                    .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.black.opacity(0.75))
                .cornerRadius(18)
                .shadow(radius: 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
    }
}

extension View {
    func reportOverlay(isPresented: Binding<Bool>) -> some View {
        modifier(ReportOverlay(isPresented: isPresented))
    }
}
