import Foundation

// MARK: - Notification Action Model
struct NotificationAction: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let type: ActionType
    let style: ActionStyle
    let data: [String: String]?
    
    init(id: String = UUID().uuidString, title: String, type: ActionType, style: ActionStyle = .default, data: [String: String]? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.style = style
        self.data = data
    }
}

// MARK: - Action Type
enum ActionType: String, Codable, CaseIterable {
    case reply = "reply"
    case view = "view"
    case dismiss = "dismiss"
    case markAsRead = "mark_as_read"
    case delete = "delete"
    case share = "share"
    case archive = "archive"
    case openSIF = "open_sif"
    case openProfile = "open_profile"
    case navigateToScreen = "navigate_to_screen"
    case openURL = "open_url"
    case scheduleReminder = "schedule_reminder"
    case customAction = "custom_action"
    
    var displayName: String {
        switch self {
        case .reply: return "Reply"
        case .view: return "View"
        case .dismiss: return "Dismiss"
        case .markAsRead: return "Mark as Read"
        case .delete: return "Delete"
        case .share: return "Share"
        case .archive: return "Archive"
        case .openSIF: return "Open SIF"
        case .openProfile: return "Open Profile"
        case .navigateToScreen: return "Navigate"
        case .openURL: return "Open Link"
        case .scheduleReminder: return "Remind Me"
        case .customAction: return "Action"
        }
    }
    
    var iconName: String {
        switch self {
        case .reply: return "arrowshape.turn.up.left"
        case .view: return "eye"
        case .dismiss: return "xmark"
        case .markAsRead: return "checkmark"
        case .delete: return "trash"
        case .share: return "square.and.arrow.up"
        case .archive: return "archivebox"
        case .openSIF: return "envelope.open"
        case .openProfile: return "person.circle"
        case .navigateToScreen: return "arrow.right"
        case .openURL: return "link"
        case .scheduleReminder: return "clock.badge.plus"
        case .customAction: return "gear"
        }
    }
}

// MARK: - Action Style
enum ActionStyle: String, Codable, CaseIterable {
    case `default` = "default"
    case destructive = "destructive"
    case cancel = "cancel"
    case primary = "primary"
    
    var isDestructive: Bool {
        return self == .destructive
    }
    
    var isPrimary: Bool {
        return self == .primary
    }
}

// MARK: - Predefined Actions
extension NotificationAction {
    static let reply = NotificationAction(
        title: "Reply",
        type: .reply,
        style: .primary
    )
    
    static let view = NotificationAction(
        title: "View",
        type: .view,
        style: .default
    )
    
    static let dismiss = NotificationAction(
        title: "Dismiss",
        type: .dismiss,
        style: .cancel
    )
    
    static let markAsRead = NotificationAction(
        title: "Mark as Read",
        type: .markAsRead,
        style: .default
    )
    
    static let delete = NotificationAction(
        title: "Delete",
        type: .delete,
        style: .destructive
    )
    
    static let share = NotificationAction(
        title: "Share",
        type: .share,
        style: .default
    )
    
    static func openSIF(sifId: String) -> NotificationAction {
        return NotificationAction(
            title: "Open SIF",
            type: .openSIF,
            style: .primary,
            data: ["sifId": sifId]
        )
    }
    
    static func openProfile(userId: String) -> NotificationAction {
        return NotificationAction(
            title: "View Profile",
            type: .openProfile,
            style: .default,
            data: ["userId": userId]
        )
    }
    
    static func navigateToScreen(screenName: String) -> NotificationAction {
        return NotificationAction(
            title: "Go to \(screenName)",
            type: .navigateToScreen,
            style: .default,
            data: ["screenName": screenName]
        )
    }
}