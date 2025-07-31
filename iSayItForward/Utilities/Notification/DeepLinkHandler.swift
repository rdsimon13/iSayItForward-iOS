import Foundation
import SwiftUI

// MARK: - Deep Link Handler
class DeepLinkHandler: ObservableObject {
    @Published var activeDeepLink: DeepLink?
    
    static let shared = DeepLinkHandler()
    
    private init() {
        setupNotificationObserver()
    }
    
    // MARK: - Deep Link Model
    struct DeepLink {
        let path: String
        let parameters: [String: String]
        let timestamp: Date
        
        init(path: String, parameters: [String: String] = [:]) {
            self.path = path
            self.parameters = parameters
            self.timestamp = Date()
        }
    }
    
    // MARK: - Setup
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .handleDeepLink,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let deepLinkString = notification.object as? String {
                self?.handleDeepLinkString(deepLinkString)
            } else if let userInfo = notification.userInfo,
                      let path = userInfo["path"] as? String,
                      let parameters = userInfo["parameters"] as? [String: String] {
                self?.handleDeepLink(path: path, parameters: parameters)
            }
        }
    }
    
    // MARK: - Deep Link Handling
    func handleDeepLinkString(_ deepLinkString: String) {
        guard let (path, parameters) = NotificationUtilities.parseDeepLink(deepLinkString) else {
            print("❌ Invalid deep link: \(deepLinkString)")
            return
        }
        
        handleDeepLink(path: path, parameters: parameters)
    }
    
    func handleDeepLink(path: String, parameters: [String: String] = [:]) {
        DispatchQueue.main.async {
            self.activeDeepLink = DeepLink(path: path, parameters: parameters)
            print("🔗 Handling deep link: \(path) with parameters: \(parameters)")
        }
    }
    
    func clearActiveDeepLink() {
        DispatchQueue.main.async {
            self.activeDeepLink = nil
        }
    }
    
    // MARK: - Navigation Helpers
    func shouldNavigateToSIF(id: String) -> Bool {
        return activeDeepLink?.path == NotificationConstants.DeepLinks.sifPath &&
               activeDeepLink?.parameters["id"] == id
    }
    
    func shouldNavigateToProfile(userId: String) -> Bool {
        return activeDeepLink?.path == NotificationConstants.DeepLinks.profilePath &&
               activeDeepLink?.parameters["id"] == userId
    }
    
    func shouldNavigateToChat(chatId: String) -> Bool {
        return activeDeepLink?.path == NotificationConstants.DeepLinks.chatPath &&
               activeDeepLink?.parameters["id"] == chatId
    }
    
    func shouldNavigateToTemplate(templateId: String) -> Bool {
        return activeDeepLink?.path == NotificationConstants.DeepLinks.templatePath &&
               activeDeepLink?.parameters["id"] == templateId
    }
    
    func shouldNavigateToAchievement(achievementId: String) -> Bool {
        return activeDeepLink?.path == NotificationConstants.DeepLinks.achievementPath &&
               activeDeepLink?.parameters["id"] == achievementId
    }
}

// MARK: - Deep Link Navigation View Modifier
struct DeepLinkNavigationModifier: ViewModifier {
    @ObservedObject var deepLinkHandler = DeepLinkHandler.shared
    @State private var showingSIFDetail = false
    @State private var showingProfileDetail = false
    @State private var showingChatDetail = false
    @State private var showingTemplateDetail = false
    @State private var showingAchievementDetail = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: deepLinkHandler.activeDeepLink) { deepLink in
                guard let deepLink = deepLink else { return }
                
                switch deepLink.path {
                case NotificationConstants.DeepLinks.sifPath:
                    showingSIFDetail = true
                case NotificationConstants.DeepLinks.profilePath:
                    showingProfileDetail = true
                case NotificationConstants.DeepLinks.chatPath:
                    showingChatDetail = true
                case NotificationConstants.DeepLinks.templatePath:
                    showingTemplateDetail = true
                case NotificationConstants.DeepLinks.achievementPath:
                    showingAchievementDetail = true
                default:
                    print("🔗 Unhandled deep link path: \(deepLink.path)")
                }
            }
            .sheet(isPresented: $showingSIFDetail) {
                DeepLinkDestinationView(
                    title: "SIF Detail",
                    content: "SIF ID: \(deepLinkHandler.activeDeepLink?.parameters["id"] ?? "Unknown")"
                )
                .onDisappear {
                    deepLinkHandler.clearActiveDeepLink()
                }
            }
            .sheet(isPresented: $showingProfileDetail) {
                DeepLinkDestinationView(
                    title: "Profile",
                    content: "User ID: \(deepLinkHandler.activeDeepLink?.parameters["id"] ?? "Unknown")"
                )
                .onDisappear {
                    deepLinkHandler.clearActiveDeepLink()
                }
            }
            .sheet(isPresented: $showingChatDetail) {
                DeepLinkDestinationView(
                    title: "Chat",
                    content: "Chat ID: \(deepLinkHandler.activeDeepLink?.parameters["id"] ?? "Unknown")"
                )
                .onDisappear {
                    deepLinkHandler.clearActiveDeepLink()
                }
            }
            .sheet(isPresented: $showingTemplateDetail) {
                DeepLinkDestinationView(
                    title: "Template",
                    content: "Template ID: \(deepLinkHandler.activeDeepLink?.parameters["id"] ?? "Unknown")"
                )
                .onDisappear {
                    deepLinkHandler.clearActiveDeepLink()
                }
            }
            .sheet(isPresented: $showingAchievementDetail) {
                DeepLinkDestinationView(
                    title: "Achievement",
                    content: "Achievement ID: \(deepLinkHandler.activeDeepLink?.parameters["id"] ?? "Unknown")"
                )
                .onDisappear {
                    deepLinkHandler.clearActiveDeepLink()
                }
            }
    }
}

// MARK: - Deep Link Destination View (Placeholder)
private struct DeepLinkDestinationView: View {
    let title: String
    let content: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.brandDarkBlue)
                
                Text("Deep Link Navigation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandDarkBlue)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("This is a placeholder view. In a real app, this would navigate to the actual content.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .background(Color.mainAppGradient.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandDarkBlue)
                }
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func handleDeepLinks() -> some View {
        modifier(DeepLinkNavigationModifier())
    }
}