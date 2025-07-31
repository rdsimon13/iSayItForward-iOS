import SwiftUI

// MARK: - Notification Filter Sheet
struct NotificationFilterSheet: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter by State
                FilterSection(title: "Filter by State") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterOptionCard(
                                title: filter.displayName,
                                icon: filter.iconName,
                                isSelected: viewModel.selectedFilter == filter,
                                onTap: {
                                    viewModel.applyFilter(filter)
                                }
                            )
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                // Filter by Category
                FilterSection(title: "Filter by Category") {
                    VStack(spacing: 12) {
                        FilterOptionCard(
                            title: "All Categories",
                            icon: "list.bullet",
                            isSelected: viewModel.selectedCategory == nil,
                            onTap: {
                                viewModel.applyCategoryFilter(nil)
                            }
                        )
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(NotificationCategory.allCases, id: \.self) { category in
                                FilterOptionCard(
                                    title: category.displayName,
                                    icon: categoryIcon(category),
                                    isSelected: viewModel.selectedCategory == category,
                                    color: categoryColor(category),
                                    onTap: {
                                        viewModel.applyCategoryFilter(category)
                                    }
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Reset Button
                if viewModel.activeFilterCount > 0 {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Filter Notifications")
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
    
    private func categoryIcon(_ category: NotificationCategory) -> String {
        switch category {
        case .sif: return "envelope.fill"
        case .social: return "person.2.fill"
        case .system: return "gear.circle.fill"
        case .template: return "doc.on.doc.fill"
        case .achievement: return "star.fill"
        }
    }
    
    private func categoryColor(_ category: NotificationCategory) -> Color {
        switch category {
        case .sif: return .brandDarkBlue
        case .social: return .green
        case .system: return .orange
        case .template: return .purple
        case .achievement: return .yellow
        }
    }
}

// MARK: - Filter Section
private struct FilterSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
            }
            
            content
        }
    }
}

// MARK: - Filter Option Card
private struct FilterOptionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    init(
        title: String,
        icon: String,
        isSelected: Bool,
        color: Color = .brandDarkBlue,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Reply View
struct NotificationReplyView: View {
    let notification: Notification
    @ObservedObject var actionViewModel: NotificationActionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var replyText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Original notification
                VStack(alignment: .leading, spacing: 12) {
                    Text("Replying to:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        NotificationBadgeView(
                            type: notification.type,
                            priority: notification.priority,
                            isRead: true
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(notification.body)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Reply text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Reply:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandDarkBlue)
                    
                    TextEditor(text: $replyText)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 120)
                        .focused($isTextFieldFocused)
                }
                
                Spacer()
                
                // Send button
                Button {
                    Task {
                        actionViewModel.replyText = replyText
                        await actionViewModel.sendReply(to: notification)
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    HStack {
                        if actionViewModel.isPerformingAction {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text("Send Reply")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.brandDarkBlue)
                    )
                }
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || actionViewModel.isPerformingAction)
            }
            .padding()
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandDarkBlue)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Quick Actions Sheet
struct NotificationQuickActionsSheet: View {
    let notification: Notification
    @ObservedObject var actionViewModel: NotificationActionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            VStack(spacing: 12) {
                HStack {
                    NotificationBadgeView(
                        type: notification.type,
                        priority: notification.priority,
                        isRead: notification.isRead
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(notification.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
            }
            .padding()
            
            // Actions
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(notification.actions) { action in
                        QuickActionRow(
                            action: action,
                            isLoading: actionViewModel.isPerformingAction,
                            onTap: {
                                Task {
                                    await actionViewModel.performAction(action, for: notification)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        )
                        
                        if action.id != notification.actions.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                    
                    // Default actions
                    Divider()
                        .padding(.leading, 60)
                    
                    QuickActionRow(
                        title: "Archive",
                        icon: "archivebox",
                        isLoading: actionViewModel.isPerformingAction,
                        onTap: {
                            Task {
                                await actionViewModel.performAction(.archive, for: notification)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    QuickActionRow(
                        title: "Delete",
                        icon: "trash",
                        color: .red,
                        isLoading: actionViewModel.isPerformingAction,
                        onTap: {
                            Task {
                                await actionViewModel.performAction(.delete, for: notification)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    )
                }
            }
            
            // Cancel button
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Quick Action Row
private struct QuickActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let onTap: () -> Void
    
    init(
        action: NotificationAction,
        isLoading: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = action.title
        self.icon = action.iconName
        self.color = Color.brandDarkBlue
        self.isLoading = isLoading
        self.onTap = onTap
    }
    
    init(
        title: String,
        icon: String,
        color: Color = .brandDarkBlue,
        isLoading: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Preview
struct NotificationFilterSheet_Previews: PreviewProvider {
    static var previews: some View {
        NotificationFilterSheet(viewModel: NotificationCenterViewModel())
    }
}