import SwiftUI

// MARK: - Notification Detail View
struct NotificationDetailView: View {
    @StateObject private var viewModel: NotificationDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(notification: Notification) {
        self._viewModel = StateObject(wrappedValue: NotificationDetailViewModel(notification: notification))
    }
    
    init(notificationId: String) {
        self._viewModel = StateObject(wrappedValue: NotificationDetailViewModel(notificationId: notificationId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                if let notification = viewModel.notification {
                    notificationDetailContent(notification)
                } else if viewModel.isLoading {
                    loadingView
                } else {
                    errorView
                }
            }
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.notification != nil {
                        notificationMenu
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingReminderSheet) {
                ReminderSchedulerSheet(viewModel: viewModel)
            }
            .alert("Delete Notification", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteNotification()
                    dismiss()
                }
            } message: {
                Text("This notification will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Content Views
    private func notificationDetailContent(_ notification: Notification) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                notificationHeader(notification)
                
                // Content
                notificationContentView(notification)
                
                // Actions
                notificationActions
                
                // Related notifications
                if viewModel.shouldShowRelatedNotifications() {
                    relatedNotificationsSection
                }
            }
            .padding()
        }
    }
    
    private func notificationHeader(_ notification: Notification) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Type icon
                notificationTypeIcon(notification)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(notification.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(viewModel.getFormattedDate())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Text("New")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Divider()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func notificationTypeIcon(_ notification: Notification) -> some View {
        let typeInfo = viewModel.getTypeDisplayInfo()
        
        return Image(systemName: typeInfo.icon)
            .font(.title)
            .foregroundColor(typeInfo.color)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(typeInfo.color.opacity(0.1))
            )
    }
    
    private func notificationContentView(_ notification: Notification) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Message content
            Text(notification.message)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Additional content based on notification type
            additionalContent(for: notification)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func additionalContent(for notification: Notification) -> some View {
        Group {
            switch notification.type {
            case .impactMilestone:
                milestoneContent(notification)
                
            case .sifReceived, .sifDelivered:
                sifContent(notification)
                
            case .messageResponse, .mention:
                messageContent(notification)
                
            default:
                EmptyView()
            }
        }
    }
    
    private func milestoneContent(_ notification: Notification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                
                Text("Achievement Unlocked")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("Your positive impact continues to grow in the community!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func sifContent(_ notification: Notification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let sifId = notification.relatedSIFId {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    
                    Text("SIF #\(sifId.prefix(8))")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Button("View SIF Details") {
                    // Handle SIF navigation
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func messageContent(_ notification: Notification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.green)
                
                Text("Message Thread")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if let sifId = notification.relatedSIFId {
                Text("Related to SIF #\(sifId.prefix(8))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Actions Section
    private var notificationActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.availableActions, id: \.id) { action in
                    ActionButton(action: action) {
                        viewModel.performAction(action)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Related Notifications
    private var relatedNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Notifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(viewModel.relatedNotifications.prefix(3), id: \.id) { notification in
                    RelatedNotificationRow(notification: notification) {
                        // Handle tap
                    }
                }
                
                if viewModel.relatedNotifications.count > 3 {
                    Button("View All (\(viewModel.relatedNotifications.count))") {
                        // Show all related notifications
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Loading and Error Views
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notification...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Load Notification")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("This notification may have been deleted or is no longer available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Menu
    private var notificationMenu: some View {
        Menu {
            Button(action: {
                viewModel.shareNotification()
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                viewModel.showingReminderSheet = true
            }) {
                Label("Remind Me", systemImage: "clock.badge.plus")
            }
            
            Divider()
            
            Button(action: {
                viewModel.showingDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let action: NotificationAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: action.iconName)
                    .font(.title2)
                    .foregroundColor(buttonColor)
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonColor: Color {
        switch action.style {
        case .primary: return .blue
        case .destructive: return .red
        case .cancel: return .gray
        case .default: return .blue
        }
    }
}

// MARK: - Related Notification Row
struct RelatedNotificationRow: View {
    let notification: Notification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: notification.type.iconName)
                    .font(.title3)
                    .foregroundColor(Color(notification.type.color))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(NotificationFormatter.formatTime(from: notification.createdDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reminder Scheduler Sheet
struct ReminderSchedulerSheet: View {
    @ObservedObject var viewModel: NotificationDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var customMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Time") {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                        .datePickerStyle(.compact)
                }
                
                Section("Custom Message (Optional)") {
                    TextField("Enter custom reminder message", text: $customMessage, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Schedule Reminder") {
                        let message = customMessage.isEmpty ? nil : customMessage
                        viewModel.scheduleReminder(at: selectedDate, customMessage: message)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(selectedDate <= Date())
                }
            }
            .navigationTitle("Schedule Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleNotification = Notification(
        userId: "user123",
        type: .messageResponse,
        title: "New Response to Your SIF",
        message: "Someone has responded to your Say It Forward message. Check it out!"
    )
    
    return NotificationDetailView(notification: sampleNotification)
}