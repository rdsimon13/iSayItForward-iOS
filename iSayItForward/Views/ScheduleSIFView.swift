import SwiftUI

struct ScheduleSIFView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: TabRouter   // ✅ shared navigation router

    @State private var selectedDate = Date()
    @State private var message = ""
    @State private var showConfirmation = false

    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isNavVisible: Bool = true   // ✅ local binding for bottom nav visibility

    var body: some View {
        ZStack(alignment: .bottom) {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection

                    // MARK: - Scheduling Card
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        .overlay(
                            VStack(alignment: .leading, spacing: 20) {
                                pill(text: "Schedule a SIF")

                                // MARK: - Date & Time Pickers
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Select Date & Time")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(BrandTheme.cardText)

                                    DatePicker(
                                        "Delivery Date",
                                        selection: $selectedDate,
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.graphical)

                                    DatePicker(
                                        "Delivery Time",
                                        selection: $selectedDate,
                                        displayedComponents: [.hourAndMinute]
                                    )
                                    .labelsHidden()
                                }

                                // MARK: - Message Field
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Message")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(BrandTheme.cardText)

                                    TextField("Enter your message...", text: $message, axis: .vertical)
                                        .lineLimit(3...6)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.white.opacity(0.95))
                                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                                        )
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                }

                                // MARK: - Confirm Button
                                Button(action: confirmSchedule) {
                                    Text("Confirm Schedule")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(BrandTheme.pillBG)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        )

                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 120)
                .trackScrollOffset(in: "scheduleScroll", offset: $scrollOffset)
            }
            .coordinateSpace(name: "scheduleScroll")
            .onChange(of: scrollOffset) { _ in
                handleScroll(offset: scrollOffset)
            }

            // ✅ Fixed Bottom Navigation Bar
            BottomNavBar(
                selectedTab: $router.selectedTab,
                isVisible: $isNavVisible
            )
            .environmentObject(router)
            .environmentObject(appState)

            if showConfirmation {
                confirmationToast
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Never forget to send greetings on that special day again.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Pill Style
    private func pill(text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(BrandTheme.pillBG)
            )
    }

    // MARK: - Confirmation Toast
    private var confirmationToast: some View {
        VStack {
            Spacer()
            Text("✅ SIF Scheduled Successfully!")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.9))
                )
                .shadow(radius: 4)
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions
    private func confirmSchedule() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showConfirmation = true
        }

        // Hide toast + return to Home tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showConfirmation = false
                router.selectedTab = .home   // ✅ use global router to navigate
            }
        }
    }

    private func handleScroll(offset: CGFloat) {
        let delta = offset - lastScrollOffset
        if abs(delta) > 8 {
            withAnimation(.easeInOut(duration: 0.25)) {
                isNavVisible = delta <= 0   // ✅ toggle visibility based on scroll direction
            }
            lastScrollOffset = offset
        }
    }
}

#Preview {
    ScheduleSIFView()
        .environmentObject(AppState())
        .environmentObject(TabRouter())
}
