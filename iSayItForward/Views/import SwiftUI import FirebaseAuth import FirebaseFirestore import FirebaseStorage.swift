import SwiftUI
import FirebaseAuth

                // MARK: - Gradient
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 1.0
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {
                    Text("Add Your Signature")
                        .font(.custom("Kodchasan-Bold", size: 24))
                        .foregroundColor(.black.opacity(0.85))
                        .padding(.top, 30)

                    VStack(spacing: 10) {
                        SignatureCanvas(paths: $paths)
                            .frame(height: 220)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3)))

                        Text("Sign inside the box above")
                            .font(.custom("Kodchasan-Regular", size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Clear") {
                            showingClearAlert = true
                        }
                        .font(.custom("Kodchasan-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                        Button("Save Signature") {
                            saveSignature()
                        }
                        .font(.custom("Kodchasan-SemiBold", size: 16))
                        .foregroundColor(.black.opacity(0.85))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "FFD700"))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.horizontal)

                    Spacer()

                    BottomNavBar(selectedTab: $selectedTab)
                        .padding(.bottom, 5)
                        .onChange(of: selectedTab) { newTab in
                            navigateTo(tab: newTab)
                        }
                }
                .alert("Clear Signature", isPresented: $showingClearAlert) {
                    Button("Clear", role: .destructive) { paths.removeAll() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to clear your signature?")
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func saveSignature() {
        guard let signatureImage = generateSignatureImage() else { return }
        guard let imageData = signatureImage.pngData() else { return }
        let userUID = Auth.auth().currentUser?.uid ?? "anonymous"
        let signatureData = SignatureData(signatureImageData: imageData, userUID: userUID)
        onSignatureComplete(signatureData)
        isPresented = false
    }

    private func generateSignatureImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 150))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 150))
            UIColor.black.setStroke()
            for path in paths {
                let bezierPath = UIBezierPath()
                bezierPath.lineWidth = path.lineWidth
                if !path.points.isEmpty {
                    bezierPath.move(to: path.points[0])
                    for point in path.points.dropFirst() {
                        bezierPath.addLine(to: point)
                    }
                    bezierPath.stroke()
                }
            }
        }
    }

    private func navigateTo(tab: String) {
        switch tab {
        case "home": navigate(to: DashboardView())
        case "compose": navigate(to: CreateSIFView())
        case "profile": navigate(to: ProfileView())
        case "schedule": navigate(to: ScheduleSIFView())
        case "settings": navigate(to: GettingStartedView())
        default: break
        }
    }

    private func navigate<Destination: View>(to destination: Destination) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = UIHostingController(rootView: destination)
        window.makeKeyAndVisible()
    }
}

*/
