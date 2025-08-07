import SwiftUI

struct UserMessageListView: View {
    let messages: [SIFItem]
    let isLoading: Bool
    let isLoadingMore: Bool
    let canLoadMore: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Shared SIFs")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                if !messages.isEmpty {
                    Text("\(messages.count) message\(messages.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                }
            }
            
            // Messages List
            if isLoading {
                LoadingMessagesList()
            } else if messages.isEmpty {
                EmptyMessagesView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageCard(message: message)
                    }
                    
                    // Load More Button
                    if canLoadMore {
                        LoadMoreButton(isLoading: isLoadingMore, onTap: onLoadMore)
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct MessageCard: View {
    let message: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date
            HStack {
                Text(message.subject.isEmpty ? "No Subject" : message.subject)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formatDate(message.createdDate))
                    .font(.caption)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.6))
            }
            
            // Message content
            Text(message.message)
                .font(.body)
                .foregroundColor(Color.brandDarkBlue.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Footer with recipient count and scheduled date
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(message.recipients.count) recipient\(message.recipients.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundColor(Color.brandYellow)
                
                Spacer()
                
                if message.scheduledDate > message.createdDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("Scheduled")
                            .font(.caption)
                    }
                    .foregroundColor(Color.brandDarkBlue.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.brandDarkBlue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brandDarkBlue.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LoadingMessagesList: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                LoadingMessageCard()
            }
        }
    }
}

struct LoadingMessageCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(width: 120, height: 16)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(width: 60, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(height: 14)
                    .frame(width: .random(in: 200...300))
            }
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(width: 80, height: 12)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.brandDarkBlue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

struct EmptyMessagesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(Color.brandDarkBlue.opacity(0.4))
            
            VStack(spacing: 8) {
                Text("No SIFs Yet")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue)
                
                Text("This user hasn't shared any public SIFs yet. Check back later!")
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

struct LoadMoreButton: View {
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.brandDarkBlue)
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(Color.brandDarkBlue)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.subheadline)
                    
                    Text("Load More SIFs")
                        .font(.subheadline)
                }
            }
            .foregroundColor(Color.brandDarkBlue)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.brandDarkBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.brandDarkBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .padding(.top, 8)
    }
}

// MARK: - Preview

struct UserMessageListView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // With messages
                UserMessageListView(
                    messages: sampleMessages,
                    isLoading: false,
                    isLoadingMore: false,
                    canLoadMore: true,
                    onLoadMore: {}
                )
                
                // Loading state
                UserMessageListView(
                    messages: [],
                    isLoading: true,
                    isLoadingMore: false,
                    canLoadMore: false,
                    onLoadMore: {}
                )
                
                // Empty state
                UserMessageListView(
                    messages: [],
                    isLoading: false,
                    isLoadingMore: false,
                    canLoadMore: false,
                    onLoadMore: {}
                )
            }
            .padding()
        }
        .background(Color.mainAppGradient)
        .preferredColorScheme(.light)
    }
    
    static let sampleMessages = [
        SIFItem(
            authorUid: "123",
            recipients: ["friend@example.com"],
            subject: "Happy Birthday!",
            message: "Wishing you the most amazing birthday filled with love, laughter, and all your favorite things!",
            createdDate: Date().addingTimeInterval(-86400),
            scheduledDate: Date()
        ),
        SIFItem(
            authorUid: "123",
            recipients: ["team@company.com", "manager@company.com"],
            subject: "Thank You",
            message: "I wanted to express my gratitude for all the support and collaboration this month. You've made such a difference!",
            createdDate: Date().addingTimeInterval(-172800),
            scheduledDate: Date()
        ),
        SIFItem(
            authorUid: "123",
            recipients: ["mom@example.com"],
            subject: "",
            message: "Just thinking of you and wanted to send some love your way. Hope you're having a wonderful day!",
            createdDate: Date().addingTimeInterval(-259200),
            scheduledDate: Date()
        )
    ]
}