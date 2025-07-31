import Foundation
import SwiftUI
import Combine
import FirebaseAuth

// MARK: - SIFTimelineViewModel
@MainActor
class SIFTimelineViewModel: ObservableObject {
    @Published var sifs: [SIFItem] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasReachedEnd = false
    
    private let timelineService = SIFTimelineService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupRealtimeUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Load initial timeline data
    func loadInitialData() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let initialSIFs = try await timelineService.fetchInitialSIFs()
                await updateSIFs(initialSIFs)
                isLoading = false
            } catch {
                errorMessage = "Failed to load timeline: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Refresh timeline data (pull-to-refresh)
    func refreshTimeline() {
        guard !isRefreshing && !isLoading else { return }
        
        isRefreshing = true
        errorMessage = nil
        hasReachedEnd = false
        
        Task {
            do {
                let refreshedSIFs = try await timelineService.refreshTimeline()
                await updateSIFs(refreshedSIFs)
                isRefreshing = false
            } catch {
                errorMessage = "Failed to refresh timeline: \(error.localizedDescription)"
                isRefreshing = false
            }
        }
    }
    
    /// Load more SIFs for infinite scrolling
    func loadMoreSIFs() {
        guard !isLoadingMore && !hasReachedEnd && !isLoading else { return }
        
        isLoadingMore = true
        
        Task {
            do {
                let moreSIFs = try await timelineService.fetchNextPage()
                
                if moreSIFs.isEmpty {
                    hasReachedEnd = true
                } else {
                    await appendSIFs(moreSIFs)
                }
                
                isLoadingMore = false
            } catch {
                errorMessage = "Failed to load more messages: \(error.localizedDescription)"
                isLoadingMore = false
            }
        }
    }
    
    /// Toggle like for a SIF
    func toggleLike(for sif: SIFItem) {
        Task {
            do {
                // Optimistically update UI
                if let index = sifs.firstIndex(where: { $0.id == sif.id }) {
                    var updatedSIF = sifs[index]
                    
                    // Toggle the like status locally first for immediate UI feedback
                    guard let currentUserId = Auth.auth().currentUser?.uid else { return }
                    
                    if updatedSIF.likes.contains(currentUserId) {
                        updatedSIF.likes.removeAll { $0 == currentUserId }
                    } else {
                        updatedSIF.likes.append(currentUserId)
                    }
                    
                    sifs[index] = updatedSIF
                }
                
                try await timelineService.toggleLike(for: sif.id ?? "", currentLikes: sif.likes)
            } catch {
                // Revert optimistic update on error
                if let index = sifs.firstIndex(where: { $0.id == sif.id }) {
                    sifs[index] = sif
                }
                errorMessage = "Failed to update like: \(error.localizedDescription)"
            }
        }
    }
    
    /// Mark SIF as read
    func markAsRead(sif: SIFItem) {
        Task {
            do {
                try await timelineService.markAsRead(sifId: sif.id ?? "")
            } catch {
                print("Failed to mark SIF as read: \(error.localizedDescription)")
            }
        }
    }
    
    /// Check if should load more content when reaching near the end
    func shouldLoadMore(for sif: SIFItem) -> Bool {
        guard let index = sifs.firstIndex(where: { $0.id == sif.id }) else {
            return false
        }
        
        // Load more when reaching the last 5 items
        return index >= sifs.count - 5
    }
    
    // MARK: - Private Methods
    
    private func setupRealtimeUpdates() {
        timelineService.startRealtimeUpdates { [weak self] updatedSIFs in
            Task { @MainActor in
                // Only update if we're not currently loading initial data
                guard let self = self, !self.isLoading else { return }
                
                // Merge new SIFs with existing ones, avoiding duplicates
                let existingIds = Set(self.sifs.compactMap { $0.id })
                let newSIFs = updatedSIFs.filter { !existingIds.contains($0.id ?? "") }
                
                if !newSIFs.isEmpty {
                    // Insert new SIFs at the beginning (they're newer)
                    self.sifs.insert(contentsOf: newSIFs, at: 0)
                }
            }
        }
    }
    
    private func updateSIFs(_ newSIFs: [SIFItem]) async {
        sifs = newSIFs
    }
    
    private func appendSIFs(_ newSIFs: [SIFItem]) async {
        sifs.append(contentsOf: newSIFs)
    }
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        return sifs.isEmpty && !isLoading
    }
    
    var showLoadingIndicator: Bool {
        return isLoading && sifs.isEmpty
    }
    
    var showEmptyState: Bool {
        return isEmpty && !isLoading && errorMessage == nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        timelineService.stopRealtimeUpdates()
    }
}

// MARK: - Timeline State
enum TimelineState {
    case loading
    case loaded
    case refreshing
    case loadingMore
    case error(String)
    case empty
}