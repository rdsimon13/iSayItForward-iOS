import SwiftUI

// MARK: - Notification Badge View
struct NotificationBadgeView: View {
    let type: NotificationType
    let priority: NotificationPriority
    let isRead: Bool
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundGradient)
                .frame(width: 44, height: 44)
            
            // Icon
            Image(systemName: type.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            // Priority indicator
            if priority == .high || priority == .critical {
                PriorityIndicator(priority: priority)
            }
            
            // Unread indicator
            if !isRead {
                UnreadIndicator()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isRead)
    }
    
    private var backgroundGradient: LinearGradient {
        let colors = gradientColors(for: type, priority: priority, isRead: isRead)
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func gradientColors(for type: NotificationType, priority: NotificationPriority, isRead: Bool) -> [Color] {
        let alpha: Double = isRead ? 0.6 : 1.0
        
        switch priority {
        case .critical:
            return [Color.red.opacity(alpha), Color.red.opacity(alpha * 0.8)]
        case .high:
            return [Color.orange.opacity(alpha), Color.orange.opacity(alpha * 0.8)]
        default:
            break
        }
        
        switch type.category {
        case .sif:
            return [Color.brandDarkBlue.opacity(alpha), Color.blue.opacity(alpha * 0.8)]
        case .social:
            return [Color.green.opacity(alpha), Color.green.opacity(alpha * 0.8)]
        case .system:
            return [Color.gray.opacity(alpha), Color.gray.opacity(alpha * 0.8)]
        case .template:
            return [Color.purple.opacity(alpha), Color.purple.opacity(alpha * 0.8)]
        case .achievement:
            return [Color.yellow.opacity(alpha), Color.orange.opacity(alpha * 0.8)]
        }
    }
}

// MARK: - Priority Indicator
private struct PriorityIndicator: View {
    let priority: NotificationPriority
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
            Spacer()
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical:
            return .red
        case .high:
            return .orange
        default:
            return .clear
        }
    }
}

// MARK: - Unread Indicator
private struct UnreadIndicator: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Circle()
                    .fill(Color.brandDarkBlue)
                    .frame(width: 6, height: 6)
                    .offset(x: -2, y: 2)
                Spacer()
            }
        }
    }
}

// MARK: - Notification Badge with Count
struct NotificationBadgeWithCountView: View {
    let count: Int
    let maxDisplayCount: Int = 99
    
    var body: some View {
        ZStack {
            // Badge background
            Circle()
                .fill(Color.red)
                .frame(width: badgeSize, height: badgeSize)
            
            // Count text
            Text(displayText)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
        }
        .opacity(count > 0 ? 1 : 0)
        .scaleEffect(count > 0 ? 1 : 0.1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }
    
    private var displayText: String {
        if count > maxDisplayCount {
            return "\(maxDisplayCount)+"
        }
        return "\(count)"
    }
    
    private var badgeSize: CGFloat {
        if count > 99 {
            return 24
        } else if count > 9 {
            return 20
        } else {
            return 18
        }
    }
    
    private var fontSize: CGFloat {
        if count > 99 {
            return 10
        } else if count > 9 {
            return 11
        } else {
            return 12
        }
    }
}

// MARK: - Category Badge View
struct NotificationCategoryBadgeView: View {
    let category: NotificationCategory
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Category icon
            Image(systemName: categoryIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(categoryColor)
            
            // Category name
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(categoryColor)
            
            // Count badge
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(categoryColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(categoryColor.opacity(0.1))
        )
    }
    
    private var categoryIcon: String {
        switch category {
        case .sif: return "envelope.fill"
        case .social: return "person.2.fill"
        case .system: return "gear.circle.fill"
        case .template: return "doc.on.doc.fill"
        case .achievement: return "star.fill"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .sif: return .brandDarkBlue
        case .social: return .green
        case .system: return .orange
        case .template: return .purple
        case .achievement: return .yellow
        }
    }
}

// MARK: - Priority Badge View
struct NotificationPriorityBadgeView: View {
    let priority: NotificationPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priorityIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(priorityColor)
            
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.15))
        )
    }
    
    private var priorityIcon: String {
        switch priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .normal: return "circle.fill"
        case .low: return "minus.circle.fill"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .normal: return .blue
        case .low: return .gray
        }
    }
}

// MARK: - State Badge View
struct NotificationStateBadgeView: View {
    let state: NotificationState
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.iconName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(stateColor)
            
            Text(state.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(stateColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .stroke(stateColor.opacity(0.5), lineWidth: 1)
                .background(Capsule().fill(stateColor.opacity(0.1)))
        )
    }
    
    private var stateColor: Color {
        switch state {
        case .pending: return .orange
        case .sent: return .blue
        case .delivered: return .green
        case .read: return .gray
        case .failed: return .red
        case .cancelled: return .red
        case .archived: return .gray
        }
    }
}

// MARK: - Animated Badge View
struct AnimatedNotificationBadgeView: View {
    let type: NotificationType
    let priority: NotificationPriority
    let isRead: Bool
    @State private var isAnimating = false
    
    var body: some View {
        NotificationBadgeView(type: type, priority: priority, isRead: isRead)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                if !isRead && priority == .critical {
                    isAnimating = true
                }
            }
            .onChange(of: isRead) { newValue in
                isAnimating = !newValue && priority == .critical
            }
    }
}

// MARK: - Preview
struct NotificationBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                NotificationBadgeView(type: .sifReceived, priority: .normal, isRead: false)
                NotificationBadgeView(type: .friendRequest, priority: .high, isRead: false)
                NotificationBadgeView(type: .systemUpdate, priority: .critical, isRead: false)
                NotificationBadgeView(type: .achievement, priority: .normal, isRead: true)
            }
            
            HStack(spacing: 16) {
                NotificationBadgeWithCountView(count: 5)
                NotificationBadgeWithCountView(count: 23)
                NotificationBadgeWithCountView(count: 150)
            }
            
            VStack(spacing: 12) {
                NotificationCategoryBadgeView(category: .sif, count: 12)
                NotificationCategoryBadgeView(category: .social, count: 3)
                NotificationCategoryBadgeView(category: .system, count: 0)
            }
            
            HStack(spacing: 12) {
                NotificationPriorityBadgeView(priority: .critical)
                NotificationPriorityBadgeView(priority: .high)
                NotificationPriorityBadgeView(priority: .normal)
                NotificationPriorityBadgeView(priority: .low)
            }
            
            HStack(spacing: 12) {
                NotificationStateBadgeView(state: .pending)
                NotificationStateBadgeView(state: .delivered)
                NotificationStateBadgeView(state: .failed)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}