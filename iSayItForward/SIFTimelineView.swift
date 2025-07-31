import SwiftUI

// MARK: - SIFTimelineView
struct SIFTimelineView: View {
    @StateObject private var viewModel = SIFTimelineViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var showingNewSIFIndicator = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    // Background gradient
                    Color.mainAppGradient.ignoresSafeArea()
                    
                    // Main content
                    mainContent
                        .refreshable {
                            await performRefresh()
                        }
                    
                    // New SIF indicator
                    if showingNewSIFIndicator {
                        newSIFIndicator
                    }
                }
                .navigationTitle("SIF Feed")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    if viewModel.sifs.isEmpty {
                        viewModel.loadInitialData()
                    }
                }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
        } else {
            // Fallback for iOS < 16
            NavigationView {
                ZStack {
                    Color.mainAppGradient.ignoresSafeArea()
                    
                    VStack {
                        Text("SIF Timeline requires iOS 16.0 or newer.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .foregroundColor(.brandDarkBlue)
                    }
                }
                .navigationTitle("SIF Feed")
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.showLoadingIndicator {
            loadingView
        } else if viewModel.showEmptyState {
            emptyStateView
        } else {
            timelineScrollView
        }
    }
    
    private var timelineScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.sifs) { sif in
                        SIFMessageCard(
                            sif: sif,
                            onLikeTapped: {
                                hapticFeedback(.light)
                                viewModel.toggleLike(for: sif)
                            },
                            onShareTapped: {
                                hapticFeedback(.medium)
                            },
                            onCardTapped: {
                                viewModel.markAsRead(sif: sif)
                            }
                        )
                        .id(sif.id)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .onAppear {
                            // Load more content when approaching the end
                            if viewModel.shouldLoadMore(for: sif) {
                                viewModel.loadMoreSIFs()
                            }
                        }
                    }
                    
                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        loadingMoreView
                    }
                    
                    // End of timeline indicator
                    if viewModel.hasReachedEnd && !viewModel.sifs.isEmpty {
                        endOfTimelineView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
            })
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .brandDarkBlue))
            
            Text("Loading your SIF timeline...")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mainAppGradient.ignoresSafeArea())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.open")
                .font(.system(size: 64))
                .foregroundColor(.brandDarkBlue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No SIFs Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandDarkBlue)
                
                Text("Be the first to share a SIF message with your community!")
                    .font(.body)
                    .foregroundColor(.brandDarkBlue.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            NavigationLink(destination: CreateSIFView()) {
                Text("Create Your First SIF")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.brandDarkBlue)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mainAppGradient.ignoresSafeArea())
    }
    
    private var loadingMoreView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .brandDarkBlue))
            
            Text("Loading more SIFs...")
                .font(.subheadline)
                .foregroundColor(.brandDarkBlue)
        }
        .padding(.vertical, 16)
    }
    
    private var endOfTimelineView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.brandYellow)
            
            Text("You're all caught up!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.brandDarkBlue)
        }
        .padding(.vertical, 24)
    }
    
    private var newSIFIndicator: some View {
        VStack {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.brandYellow)
                
                Text("New SIFs available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.95))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .onTapGesture {
                withAnimation(.spring()) {
                    showingNewSIFIndicator = false
                    viewModel.refreshTimeline()
                }
            }
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func performRefresh() async {
        await withAnimation(.spring()) {
            viewModel.refreshTimeline()
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}

// MARK: - ScrollOffset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct SIFTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            SIFTimelineView()
        } else {
            Text("Preview requires iOS 16.0 or newer")
        }
    }
}