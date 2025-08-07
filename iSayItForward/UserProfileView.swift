import SwiftUI

struct UserProfileView: View {
    let userUID: String
    
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let profile = viewModel.profile {
                    ProfileContentView(profile: profile, viewModel: viewModel)
                } else {
                    ErrorView(message: viewModel.errorMessage ?? "Failed to load profile") {
                        Task {
                            await viewModel.loadProfile(uid: userUID)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if let profile = viewModel.profile {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.showShareSheet()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile(uid: userUID)
        }
        .refreshable {
            await viewModel.refreshProfile()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let profile = viewModel.profile {
                SharedProfileActionSheet(
                    profile: profile,
                    shareURL: viewModel.getShareURL(),
                    shareText: viewModel.getShareText(),
                    isPresented: $viewModel.showingShareSheet
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
        }
        .sheet(isPresented: $viewModel.showingReportSheet) {
            if let profile = viewModel.profile {
                ReportUserActionSheet(
                    profile: profile,
                    isPresented: $viewModel.showingReportSheet
                ) { reason, details in
                    Task {
                        await viewModel.reportUser(reason: reason, details: details)
                    }
                }
            }
        }
    }
}

struct ProfileContentView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                ProfileHeaderView(
                    profile: profile,
                    isFollowing: viewModel.isFollowing,
                    onFollowTap: {
                        Task {
                            await viewModel.toggleFollow()
                        }
                    },
                    onReportTap: {
                        viewModel.showReportSheet()
                    },
                    onShareTap: {
                        viewModel.showShareSheet()
                    }
                )
                .padding(.top)
                
                // Statistics
                DetailedStatisticsView(profile: profile)
                    .padding(.horizontal)
                
                // Messages List
                UserMessageListView(
                    messages: viewModel.messages,
                    isLoading: viewModel.isLoadingMessages,
                    isLoadingMore: viewModel.isLoadingMoreMessages,
                    canLoadMore: viewModel.canLoadMoreMessages,
                    onLoadMore: {
                        Task {
                            await viewModel.loadMoreMessages()
                        }
                    }
                )
                .padding(.horizontal)
                
                // Bottom spacing
                Spacer(minLength: 20)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Loading header
            VStack(spacing: 16) {
                LoadingProfileImage()
                LoadingProfileInfo()
                LoadingActionButtons()
            }
            .padding(.top)
            
            // Loading statistics
            LoadingStatistics()
                .padding(.horizontal)
            
            // Loading messages
            LoadingMessagesList()
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct LoadingProfileImage: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct LoadingProfileInfo: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
                .frame(width: 180, height: 24)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.15))
                .frame(width: 140, height: 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: 120, height: 12)
        }
    }
}

struct LoadingActionButtons: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 40)
            
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 40)
        }
    }
}

struct LoadingStatistics: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.brandDarkBlue.opacity(0.1))
                    .frame(width: 140, height: 20)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    LoadingStatCard()
                }
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct LoadingStatCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.brandDarkBlue.opacity(0.1))
                .frame(width: 40, height: 40)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brandDarkBlue.opacity(0.1))
                .frame(width: 60, height: 20)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brandDarkBlue.opacity(0.05))
                .frame(width: 80, height: 12)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.brandDarkBlue.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))
            
            VStack(spacing: 12) {
                Text("Unable to Load Profile")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userUID: "sample-uid")
            .preferredColorScheme(.light)
    }
}