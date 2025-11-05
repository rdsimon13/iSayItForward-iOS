import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CreateSIFView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    @State private var showSignatureSheet = false
    @State private var showToast = false
    @State private var showValidationAlert = false
    @State private var isNavVisible: Bool = true

    @State private var selectedDelivery = "One-to-One"
    @State private var recipient = ""
    @State private var messageText = ""
    @State private var selectedTone = "Appreciative"
    @State private var signatureData: Data?

    private let deliveryTypes = ["One-to-One", "One-to-Many", "Group"]
    private let tones = ["Appreciative", "Encouraging", "Reflective", "Playful", "Serious"]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.0, green: 0.796, blue: 1.0), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    deliveryTypeSection
                    recipientSection
                    templateSection
                    messageSection
                    signatureSection
                    toneEmotionSection
                    sendButton
                }
                .padding(.bottom, 120)
                .padding(.horizontal, 20)
            }

            BottomNavBar(selectedTab: $router.selectedTab, isVisible: $isNavVisible)
                .environmentObject(router)
                .environmentObject(authState)
                .padding(.bottom, 8)

            if showToast {
                successToast
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSignatureSheet) {
            SignatureView(isPresented: $showSignatureSheet) { sig in
                self.signatureData = sig.signatureImageData
            }
            .environmentObject(router)
            .environmentObject(authState)
        }
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please fill out all required fields before sending.")
        }
    }

    // MARK: - Sections
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Compose Your SIF")
                .font(.custom("AvenirNext-DemiBold", size: 24))
                .foregroundColor(Color(hex: "132E37"))
            Text("Craft your message, add your tone, and express yourself beautifully.")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var deliveryTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery Type")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            HStack(spacing: 8) {
                ForEach(deliveryTypes, id: \.self) { type in
                    Button {
                        selectedDelivery = type
                    } label: {
                        Text(type)
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedDelivery == type ? Color.blue.opacity(0.8) : Color.white.opacity(0.9))
                            )
                            .foregroundColor(selectedDelivery == type ? .white : .black)
                            .shadow(radius: selectedDelivery == type ? 2 : 0)
                    }
                }
            }
        }
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recipient")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            TextField("Enter recipient’s name or email", text: $recipient)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Templates")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            Button {
                router.selectedTab = .gallery
            } label: {
                HStack {
                    Text("Explore SIF templates to speed up your message creation.")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundColor(.black.opacity(0.75))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Message")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            TextEditor(text: $messageText)
                .frame(height: 120)
                .padding(6)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signature")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            Button("Add Signature") {
                showSignatureSheet = true
            }
            .font(.custom("AvenirNext-Medium", size: 16))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "132E37"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var toneEmotionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tone & Emotion")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            Picker("Select Tone", selection: $selectedTone) {
                ForEach(tones, id: \.self) { tone in
                    Text(tone).tag(tone)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var sendButton: some View {
        Button {
            if messageText.isEmpty || recipient.isEmpty {
                showValidationAlert = true
            } else {
                withAnimation {
                    showToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showToast = false }
                }
            }
        } label: {
            Text("Send SIF")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.gradient)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }

    private var successToast: some View {
        VStack {
            Spacer()
            Text("✅ SIF Sent Successfully!")
                .font(.custom("AvenirNext-Medium", size: 15))
                .padding()
                .background(Capsule().fill(Color.green.opacity(0.9)))
                .foregroundColor(.white)
                .shadow(radius: 4)
                .padding(.bottom, 100)
        }
    }
}

#Preview {
    CreateSIFView()
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
