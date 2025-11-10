import SwiftUI

struct TemplateDetailView: View {
    let template: TemplateModel
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            // MARK: - Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // ✅ Replaced template.imageName with system icon + color background
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(template.color)
                            .frame(height: 250)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)

                        Image(systemName: template.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.black.opacity(0.85))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                    // MARK: - Template Info
                    VStack(spacing: 12) {
                        Text(template.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "132E37"))

                        Text(template.subtitle)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Divider()
                            .frame(width: 120)
                            .background(Color.gray.opacity(0.5))

                        Text("“Creativity begins with inspiration.” ✨")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)

                    // MARK: - Use Template Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showConfirmation = true
                        }
                    }) {
                        Text("Use This Template")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.15, green: 0.25, blue: 0.35))
                            )
                            .padding(.horizontal, 30)
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                    }
                    .padding(.top, 20)
                }
            }

            // MARK: - Confirmation Popup
            if showConfirmation {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showConfirmation = false
                        }
                    }

                VStack(spacing: 15) {
                    Text("Proceed to Create Your SIF?")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.85))

                    HStack(spacing: 20) {
                        Button("Cancel") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showConfirmation = false
                            }
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 22)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))

                        NavigationLink(destination: CreateSIFView()
                            .environmentObject(appState)
                            .navigationBarHidden(true)
                        ) {
                            Text("Yes, Continue")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 22)
                                .background(Capsule().fill(Color.green.opacity(0.9)))
                                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showConfirmation)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
        }
    }
}
