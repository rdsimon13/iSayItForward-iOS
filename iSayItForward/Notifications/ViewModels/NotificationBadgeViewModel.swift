import Foundation
import SwiftUI
import Combine

// MARK: - Notification Badge View Model
class NotificationBadgeViewModel: ObservableObject {
    
    @Published var badgeCount: Int = 0
    @Published var showBadge: Bool = false
    @Published var badgeText: String = ""
    @Published var isAnimating: Bool = false
    @Published var badgeColor: Color = .red
    @Published var pulseAnimation: Bool = false
    
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    
    // Configuration
    private let maxDisplayCount = 99
    private let animationDuration: TimeInterval = 0.3
    private let pulseInterval: TimeInterval = 2.0
    
    init() {
        setupBindings()
        loadBadgeCount()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to notification service unread count
        notificationService.$unreadCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.updateBadgeCount(count)
            }
            .store(in: &cancellables)
        
        // Update badge text when count changes
        $badgeCount
            .map { [weak self] count in
                self?.formatBadgeText(count) ?? ""
            }
            .assign(to: \.badgeText, on: self)
            .store(in: &cancellables)
        
        // Update badge visibility
        $badgeCount
            .map { $0 > 0 }
            .assign(to: \.showBadge, on: self)
            .store(in: &cancellables)
    }
    
    private func loadBadgeCount() {
        // Load stored badge count
        let storedCount = UserDefaults.standard.integer(forKey: NotificationConstants.UserDefaults.badgeCount)
        updateBadgeCount(storedCount)
    }
    
    // MARK: - Badge Management
    private func updateBadgeCount(_ newCount: Int) {
        let oldCount = badgeCount
        badgeCount = newCount
        
        // Store badge count
        UserDefaults.standard.set(newCount, forKey: NotificationConstants.UserDefaults.badgeCount)
        
        // Trigger animation if count increased
        if newCount > oldCount && newCount > 0 {
            animateBadgeIncrease()
        }
        
        // Update badge color based on count
        updateBadgeColor(newCount)
        
        // Start or stop pulse animation
        updatePulseAnimation(newCount)
    }
    
    private func formatBadgeText(_ count: Int) -> String {
        if count <= 0 {
            return ""
        } else if count <= maxDisplayCount {
            return "\(count)"
        } else {
            return "\(maxDisplayCount)+"
        }
    }
    
    private func updateBadgeColor(_ count: Int) {
        switch count {
        case 0:
            badgeColor = .clear
        case 1...5:
            badgeColor = .blue
        case 6...10:
            badgeColor = .orange
        default:
            badgeColor = .red
        }
    }
    
    // MARK: - Animations
    private func animateBadgeIncrease() {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // Bounce animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            // The animation will be handled by the view
        }
        
        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.isAnimating = false
        }
    }
    
    private func updatePulseAnimation(_ count: Int) {
        animationTimer?.invalidate()
        
        if count > 0 {
            startPulseAnimation()
        } else {
            pulseAnimation = false
        }
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: pulseInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.badgeCount > 0 else {
                self?.animationTimer?.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                self.pulseAnimation.toggle()
            }
        }
    }
    
    // MARK: - Public Methods
    func clearBadge() {
        updateBadgeCount(0)
        notificationService.clearBadge()
    }
    
    func incrementBadge(by amount: Int = 1) {
        updateBadgeCount(badgeCount + amount)
    }
    
    func decrementBadge(by amount: Int = 1) {
        let newCount = max(0, badgeCount - amount)
        updateBadgeCount(newCount)
    }
    
    func setBadgeCount(_ count: Int) {
        updateBadgeCount(max(0, count))
    }
    
    // MARK: - Badge Styles
    func getBadgeSize() -> CGSize {
        let textLength = badgeText.count
        
        if textLength <= 1 {
            return CGSize(width: 20, height: 20)
        } else if textLength <= 2 {
            return CGSize(width: 24, height: 20)
        } else {
            return CGSize(width: 28, height: 20)
        }
    }
    
    func getBadgeOffset() -> CGSize {
        return CGSize(width: 8, height: -8)
    }
    
    func getBadgeFont() -> Font {
        if badgeText.count <= 2 {
            return .caption2.bold()
        } else {
            return .caption2
        }
    }
    
    // MARK: - Category-specific badges
    func getBadgeCount(for category: NotificationCategory) -> Int {
        let categoryNotifications = notificationService.notifications.filter { 
            $0.type.category == category && !$0.isRead 
        }
        return categoryNotifications.count
    }
    
    func getBadgeCount(for type: NotificationType) -> Int {
        let typeNotifications = notificationService.notifications.filter { 
            $0.type == type && !$0.isRead 
        }
        return typeNotifications.count
    }
    
    func getBadgeCount(for priority: NotificationPriority) -> Int {
        let priorityNotifications = notificationService.notifications.filter { 
            $0.priority == priority && !$0.isRead 
        }
        return priorityNotifications.count
    }
    
    // MARK: - Multi-badge support
    func getTabBadgeCount(for tab: AppTab) -> Int {
        switch tab {
        case .notifications:
            return badgeCount
        case .messages:
            return getBadgeCount(for: .messages)
        case .milestones:
            return getBadgeCount(for: .milestones)
        case .social:
            return getBadgeCount(for: .social)
        default:
            return 0
        }
    }
    
    // MARK: - Badge animations for different events
    func animateForNewMessage() {
        badgeColor = .blue
        animateBadgeIncrease()
    }
    
    func animateForMilestone() {
        badgeColor = .orange
        animateBadgeIncrease()
        
        // Special celebration animation for milestones
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            // Additional visual effects can be added here
        }
    }
    
    func animateForUrgentNotification() {
        badgeColor = .red
        animateBadgeIncrease()
        
        // More aggressive pulse for urgent notifications
        withAnimation(.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    // MARK: - Accessibility
    var accessibilityLabel: String {
        if badgeCount == 0 {
            return "No unread notifications"
        } else if badgeCount == 1 {
            return "1 unread notification"
        } else if badgeCount <= maxDisplayCount {
            return "\(badgeCount) unread notifications"
        } else {
            return "More than \(maxDisplayCount) unread notifications"
        }
    }
    
    var accessibilityHint: String {
        return "Double tap to view notifications"
    }
}

// MARK: - App Tab Enumeration
enum AppTab: String, CaseIterable {
    case home = "home"
    case messages = "messages"
    case notifications = "notifications"
    case milestones = "milestones"
    case social = "social"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .messages: return "Messages"
        case .notifications: return "Notifications"
        case .milestones: return "Milestones"
        case .social: return "Social"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .messages: return "envelope"
        case .notifications: return "bell"
        case .milestones: return "trophy"
        case .social: return "person.3"
        case .profile: return "person.circle"
        }
    }
}

// MARK: - Badge Animation State
struct BadgeAnimationState {
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var rotation: Double = 0.0
    var offset: CGSize = .zero
    
    static let bounceIn = BadgeAnimationState(scale: 1.2, opacity: 1.0)
    static let bounceOut = BadgeAnimationState(scale: 1.0, opacity: 1.0)
    static let fadeOut = BadgeAnimationState(scale: 0.8, opacity: 0.0)
    static let pulse = BadgeAnimationState(scale: 1.1, opacity: 0.8)
}