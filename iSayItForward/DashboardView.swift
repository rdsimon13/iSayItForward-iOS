import SwiftUI
import FirebaseAuth

// Assuming TextStyles and GradientTheme are defined elsewhere

struct DashboardView: View {
    @State private var displayName: String = ""
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            // ✅ TWEAK 2: Flipped Radial Gradient colors
            RadialGradient(
                gradient: Gradient(stops: [
                    // Cyan (#00CCFF) at the top (0%)
                    .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                    // White (#FFFFFF) at the bottom (100%)
                    .init(color: Color.white, location: 1.0)
                ]),
                center: .top, // Keep center at the top
                startRadius: 0,
                // Adjust end radius slightly if needed to control the fade spread
                endRadius: UIScreen.main.bounds.height * 1.0
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header (No changes needed)
                        VStack(spacing: 8) {
                            Image("isiFLogo").resizable().scaledToFit().frame(height: 100)
                                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                                .padding(.top, 25)
                            ZStack {
                                Text("iSayItForward").font(.custom("AvenirNext-Bold", size: 38)).foregroundColor(Color.black.opacity(0.4)).offset(x: 1, y: 1.5)
                                Text("iSayItForward").font(.custom("AvenirNext-Bold", size: 38)).foregroundColor(.white)
                            }.shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            Text("The Ultimate Way to Express Yourself").font(.custom("AvenirNext-Medium", size: 16)).foregroundColor(Color.black.opacity(0.6)).padding(.bottom, 10)
                        }

                        // MARK: - Welcome Card (No changes needed)
                        VStack(spacing: 6) {
                            Text("Welcome to iSIF, \(displayName.isEmpty ? "Damon" : displayName).").font(.custom("AvenirNext-DemiBold", size: 18)).foregroundColor(Color.black.opacity(0.85))
                            Text("Choose an option below to get started.").font(.custom("AvenirNext-Regular", size: 15)).foregroundColor(Color.black.opacity(0.65))
                        }.padding(20).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.8), lineWidth: 1.5)).shadow(color: .black.opacity(0.05), radius: 3, y: 2))
                        .padding(.horizontal, 28)

                        // MARK: - Feature Buttons Row (Background Removed)
                        HStack(spacing: 15) {
                            // GETTING STARTED (First Icon)
                            VStack(spacing: 6) {
                                Image("Large FAB").resizable().scaledToFit().frame(width: 70, height: 70).offset(x: 10, y: 10)
                                Text("Getting\nStarted").font(.custom("AvenirNext-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(Color.black.opacity(0.75)).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 100, height: 100)
                            // ✅ TWEAK 1: Removed the .background modifier

                            // CREATE A SIF (Second Icon)
                            VStack(spacing: 6) {
                                Image("Large FAB-1").resizable().scaledToFit().frame(width: 75, height: 75)
                                Text("CREATE\nA SIF").font(.custom("AvenirNext-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(Color.black.opacity(0.75)).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 100, height: 100)
                            // ✅ TWEAK 1: Removed the .background modifier

                            // MANAGE MY SIF’S (Third Icon)
                            VStack(spacing: 6) {
                                Image("Large FAB-2").resizable().scaledToFit().frame(width: 75, height: 75)
                                Text("MANAGE\nMY SIF'S").font(.custom("AvenirNext-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(Color.black.opacity(0.75)).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 100, height: 100)
                            // ✅ TWEAK 1: Removed the .background modifier
                        }


                        // Divider bar (No changes needed)
                        Rectangle().fill(Color.gray.opacity(0.5)).frame(height: 1.5).cornerRadius(1).padding(.horizontal, 40).padding(.top, 14).shadow(color: .black.opacity(0.1), radius: 1, y: 1)

                        // MARK: - SIF Template Gallery (No changes needed)
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                Button {} label: { Text("SIF Template Gallery").font(.custom("AvenirNext-DemiBold", size: 16)).foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 15).background(Capsule().fill(Color(red: 0.15, green: 0.25, blue: 0.35)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)) }
                                Text("Explore a variety of ready made templates designed to help you express yourself with style and speed.").font(.custom("AvenirNext-Regular", size: 14)).foregroundColor(Color.black.opacity(0.75)).multilineTextAlignment(.leading).lineLimit(3).padding(.leading, 15)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Image("4 2").resizable().scaledToFit().frame(height: 70).shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                        }.padding(.horizontal, 15).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)).shadow(color: .black.opacity(0.05), radius: 3, y: 2))
                        .padding(.horizontal, 28).padding(.top, 4)

                        // MARK: - Schedule Section (No changes needed)
                        HStack(alignment: .center, spacing: 10) {
                            Image("5 2").resizable().scaledToFit().frame(height: 70).shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                            VStack(alignment: .trailing, spacing: 5) {
                                Button {} label: { Text("Schedule a SIF").font(.custom("AvenirNext-DemiBold", size: 16)).foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 15).background(Capsule().fill(Color(red: 0.15, green: 0.25, blue: 0.35)).shadow(color: .black.opacity(0.3), radius: 4, y: 2)) }
                                Text("Never forget to send greetings on that special day ever again. Schedule your SIF for future delivery today!").font(.custom("AvenirNext-Regular", size: 14)).foregroundColor(Color.black.opacity(0.75)).multilineTextAlignment(.trailing).lineLimit(3).padding(.trailing, 15)
                            }.frame(maxWidth: .infinity, alignment: .trailing)
                        }.padding(.horizontal, 15).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)).shadow(color: .black.opacity(0.05), radius: 3, y: 2))
                        .padding(.horizontal, 28).padding(.top, 6)

                        Spacer(minLength: 10)
                    } // End Main VStack
                } // End ScrollView

                Spacer()

                // MARK: - Bottom Navigation (No changes needed)
                DashboardNavBar(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.15), radius: 8, y: 4))
                    .padding(.horizontal)
                    .padding(.bottom, 5)

            } // End Outer VStack
            .onAppear {
                if let user = Auth.auth().currentUser {
                    displayName = user.displayName ?? user.email?.components(separatedBy: "@").first?.capitalized ?? ""
                }
            }
        }
    }
}

// MARK: - Bottom Nav Structs (No changes needed)
enum Tab { case home, compose, profile, schedule, settings }

struct DashboardNavBar: View {
    @Binding var selectedTab: Tab
    var body: some View {
        HStack {
            DashboardTab(icon: "house.fill", label: "Home", tab: .home, selectedTab: $selectedTab)
            DashboardTab(icon: "square.and.pencil", label: "Compose", tab: .compose, selectedTab: $selectedTab)
            DashboardTab(icon: "person.fill", label: "Profile", tab: .profile, selectedTab: $selectedTab)
            DashboardTab(icon: "calendar", label: "Schedule", tab: .schedule, selectedTab: $selectedTab)
            DashboardTab(icon: "gearshape.fill", label: "Settings", tab: .settings, selectedTab: $selectedTab)
        }
    }
}

struct DashboardTab: View {
    let icon: String
    let label: String
    let tab: Tab
    @Binding var selectedTab: Tab
    var isActive: Bool { selectedTab == tab }
    var body: some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isActive ? Color(red: 0.651, green: 0.451, blue: 0.200) : .gray.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthState()) // Ensure AuthState is accessible
}
