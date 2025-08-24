import Foundation

// MARK: - Notification Action
struct NotificationAction: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let type: ActionType
    let style: ActionStyle
    let data: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        type: ActionType,
        style: ActionStyle = .default,
        data: [String: String]? = nil
    ) {
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
    case accept = "accept"
    case decline = "decline"
    case view = "view"
    case delete = "delete"
    case archive = "archive"
    case share = "share"
    case remind = "remind"
    case openSIF = "open_sif"
    case openProfile = "open_profile"
    case openChat = "open_chat"
    case openTemplate = "open_template"
    case dismiss = "dismiss"
    
    var displayName: String {
        switch self {
        case .reply: return "Reply"
        case .accept: return "Accept"
        case .decline: return "Decline"
        case .view: return "View"
        case .delete: return "Delete"
        case .archive: return "Archive"
        case .share: return "Share"
        case .remind: return "Remind"
        case .openSIF: return "Open SIF"
        case .openProfile: return "View Profile"
        case .openChat: return "Open Chat"
        case .openTemplate: return "View Template"
        case .dismiss: return "Dismiss"
        }
    }
    
    var iconName: String {
        switch self {
        case .reply: return "arrowshape.turn.up.left.fill"
        case .accept: return "checkmark.circle.fill"
        case .decline: return "xmark.circle.fill"
        case .view: return "eye.fill"
        case .delete: return "trash.fill"
        case .archive: return "archivebox.fill"
        case .share: return "square.and.arrow.up.fill"
        case .remind: return "bell.fill"
        case .openSIF: return "envelope.open.fill"
        case .openProfile: return "person.circle.fill"
        case .openChat: return "message.fill"
        case .openTemplate: return "doc.fill"
        case .dismiss: return "xmark"
        }
    }
}

// MARK: - Action Style
enum ActionStyle: String, Codable, CaseIterable {
    case `default` = "default"
    case destructive = "destructive"
    case cancel = "cancel"
    case primary = "primary"
    
    var buttonColor: String {
        switch self {
        case .default: return "blue"
        case .destructive: return "red"
        case .cancel: return "gray"
        case .primary: return "green"
        }
    }
}

// MARK: - Predefined Actions
extension NotificationAction {
    static let reply = NotificationAction(title: "Reply", type: .reply, style: .primary)
    static let accept = NotificationAction(title: "Accept", type: .accept, style: .primary)
    static let decline = NotificationAction(title: "Decline", type: .decline, style: .destructive)
    static let view = NotificationAction(title: "View", type: .view, style: .default)
    static let delete = NotificationAction(title: "Delete", type: .delete, style: .destructive)
    static let archive = NotificationAction(title: "Archive", type: .archive, style: .default)
    static let dismiss = NotificationAction(title: "Dismiss", type: .dismiss, style: .cancel)
    
    // SIF-specific actions
    static let openSIF = NotificationAction(title: "Open SIF", type: .openSIF, style: .primary)
    static let shareSIF = NotificationAction(title: "Share", type: .share, style: .default)
    
    // Social actions
    static let openProfile = NotificationAction(title: "View Profile", type: .openProfile, style: .default)
    static let openChat = NotificationAction(title: "Open Chat", type: .openChat, style: .primary)
    
    // Template actions
    static let openTemplate = NotificationAction(title: "View Template", type: .openTemplate, style: .primary)
}

// MARK: - Action Factory
struct NotificationActionFactory {
    static func actionsFor(notificationType: NotificationType) -> [NotificationAction] {
        switch notificationType {
        case .sifReceived:
            return [.openSIF, .reply, .archive]
        case .friendRequest:
            return [.accept, .decline, .openProfile]
        case .messageReceived:
            return [.reply, .openChat, .archive]
        case .templateShared:
            return [.openTemplate, .shareSIF, .dismiss]
        case .sifDelivered, .sifScheduled:
            return [.view, .dismiss]
        case .achievement, .milestone:
            return [.view, .shareSIF, .dismiss]
        default:
            return [.view, .dismiss]
        }
    }
}