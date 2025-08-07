import Foundation
import SwiftUI
import FirebaseFirestore

// ViewModel for managing user profile view state and operations
@MainActor
class UserProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: UserProfile?
    @Published var messages: [SIFItem] = []
    @Published var isFollowing: Bool = false
    @Published var isLoading: Bool = false
    @Published var isLoadingMessages: Bool = false
    @Published var isLoadingMoreMessages: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var showingReportSheet: Bool = false
    @Published var showingShareSheet: Bool = false
    
    // MARK: - Private Properties
    
    private let service = UserProfileService()
    private var lastMessageDocument: DocumentSnapshot?
    private var hasMoreMessages: Bool = true
    private let messagesPageSize: Int = 20
    
    // MARK: - Public Properties
    
    var canLoadMoreMessages: Bool {
        hasMoreMessages && !isLoadingMoreMessages
    }
    
    var statisticsItems: [StatisticItem] {
        guard let profile = profile else { return [] }
        return [
            StatisticItem(title: "SIFs Shared", value: "\(profile.sifsSharedCount)", icon: "envelope.fill"),
            StatisticItem(title: "Followers", value: "\(profile.followersCount)", icon: "person.2.fill"),
            StatisticItem(title: "Following", value: "\(profile.followingCount)", icon: "person.fill.badge.plus"),
            StatisticItem(title: "Impact Score", value: "\(profile.totalImpactScore)", icon: "heart.fill")
        ]
    }
    
    // MARK: - Profile Loading
    
    /// Load user profile and initial data
    func loadProfile(uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load profile data
            let profileData = try await service.fetchUserProfile(uid: uid)
            self.profile = profileData
            
            // Track the profile view
            service.trackProfileView(profileUID: uid)
            
            // Check follow status
            let followStatus = try await service.checkFollowStatus(targetUID: uid)
            self.isFollowing = followStatus
            
            // Load initial messages
            await loadMessages(uid: uid, isInitialLoad: true)
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
        
        isLoading = false
    }
    
    /// Refresh profile data
    func refreshProfile() async {
        guard let uid = profile?.uid else { return }
        
        // Clear cached data and reload
        service.removeCachedProfile(uid: uid)
        await loadProfile(uid: uid)
    }
    
    // MARK: - Message Loading
    
    /// Load messages for the user
    private func loadMessages(uid: String, isInitialLoad: Bool = false) async {
        if isInitialLoad {
            isLoadingMessages = true
            messages.removeAll()
            lastMessageDocument = nil
            hasMoreMessages = true
        } else {
            isLoadingMoreMessages = true
        }
        
        do {
            let result = try await service.fetchUserMessages(
                uid: uid,
                limit: messagesPageSize,
                lastDocument: isInitialLoad ? nil : lastMessageDocument
            )
            
            if isInitialLoad {
                self.messages = result.messages
            } else {
                self.messages.append(contentsOf: result.messages)
            }
            
            self.lastMessageDocument = result.lastDocument
            self.hasMoreMessages = result.messages.count == messagesPageSize
            
        } catch {
            self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
            self.showingError = true
        }
        
        if isInitialLoad {
            isLoadingMessages = false
        } else {
            isLoadingMoreMessages = false
        }
    }
    
    /// Load more messages (pagination)
    func loadMoreMessages() async {
        guard let uid = profile?.uid, canLoadMoreMessages else { return }
        await loadMessages(uid: uid, isInitialLoad: false)
    }
    
    // MARK: - Follow Actions
    
    /// Toggle follow status for the current profile
    func toggleFollow() async {
        guard let uid = profile?.uid else { return }
        
        do {
            let newFollowStatus = try await service.toggleFollow(targetUID: uid)
            self.isFollowing = newFollowStatus
            
            // Update local follower count optimistically
            if var currentProfile = self.profile {
                currentProfile = UserProfile(
                    uid: currentProfile.uid,
                    name: currentProfile.name,
                    email: currentProfile.email,
                    bio: currentProfile.bio,
                    profileImageURL: currentProfile.profileImageURL,
                    joinDate: currentProfile.joinDate,
                    followersCount: currentProfile.followersCount + (newFollowStatus ? 1 : -1),
                    followingCount: currentProfile.followingCount,
                    sifsSharedCount: currentProfile.sifsSharedCount,
                    totalImpactScore: currentProfile.totalImpactScore
                )
                self.profile = currentProfile
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
    
    // MARK: - Report Actions
    
    /// Show report sheet
    func showReportSheet() {
        showingReportSheet = true
    }
    
    /// Report user with reason and details
    func reportUser(reason: String, details: String) async {
        guard let uid = profile?.uid else { return }
        
        do {
            try await service.reportUser(targetUID: uid, reason: reason, details: details)
            
            // Show success message
            self.errorMessage = "User reported successfully. Thank you for helping keep our community safe."
            self.showingError = true
            
        } catch {
            self.errorMessage = "Failed to report user: \(error.localizedDescription)"
            self.showingError = true
        }
        
        showingReportSheet = false
    }
    
    // MARK: - Share Actions
    
    /// Show share sheet
    func showShareSheet() {
        showingShareSheet = true
    }
    
    /// Generate share URL for the profile
    func getShareURL() -> URL? {
        guard let uid = profile?.uid else { return nil }
        return URL(string: "isayitforward://profile/\(uid)")
    }
    
    /// Generate share text for the profile
    func getShareText() -> String {
        guard let profile = profile else {
            return "Check out this profile on iSayItForward!"
        }
        
        return "Check out \(profile.name)'s profile on iSayItForward! They've shared \(profile.sifsSharedCount) SIFs and have an impact score of \(profile.totalImpactScore)."
    }
    
    // MARK: - Error Handling
    
    /// Clear current error
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    /// Handle general errors
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - Supporting Data Models

struct StatisticItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
}

// MARK: - Report Reasons

enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment"
    case inappropriateContent = "Inappropriate Content"
    case fakeProfile = "Fake Profile"
    case other = "Other"
    
    var description: String {
        switch self {
        case .spam:
            return "This user is sending spam messages"
        case .harassment:
            return "This user is harassing others"
        case .inappropriateContent:
            return "This user is sharing inappropriate content"
        case .fakeProfile:
            return "This appears to be a fake profile"
        case .other:
            return "Other reason (please specify in details)"
        }
    }
}