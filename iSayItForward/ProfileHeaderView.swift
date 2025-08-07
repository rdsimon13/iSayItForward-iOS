import SwiftUI

struct ProfileHeaderView: View {
    let profile: UserProfile
    let isFollowing: Bool
    let onFollowTap: () -> Void
    let onReportTap: () -> Void
    let onShareTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ProfileImageView(profile: profile)
            
            // User Info
            VStack(spacing: 8) {
                Text(profile.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                Text(profile.memberSince)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Follow/Unfollow Button
                Button(action: onFollowTap) {
                    HStack(spacing: 8) {
                        Image(systemName: isFollowing ? "person.fill.checkmark" : "person.fill.badge.plus")
                        Text(isFollowing ? "Following" : "Follow")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isFollowing ? Color.brandDarkBlue : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        isFollowing ? .white : Color.brandDarkBlue.opacity(0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white, lineWidth: isFollowing ? 0 : 1)
                    )
                }
                
                // Share Button
                Button(action: onShareTap) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.brandDarkBlue.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 1)
                        )
                }
                
                // Report Button
                Button(action: onReportTap) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ProfileImageView: View {
    let profile: UserProfile
    private let imageSize: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: imageSize, height: imageSize)
                .shadow(radius: 10)
            
            // Profile image or initials
            if let imageURL = profile.profileImageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    InitialsView(initials: profile.initials)
                }
                .frame(width: imageSize - 8, height: imageSize - 8)
                .clipShape(Circle())
            } else {
                InitialsView(initials: profile.initials)
            }
        }
    }
}

struct InitialsView: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brandDarkBlue.opacity(0.8))
            .clipShape(Circle())
    }
}

// MARK: - Preview

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ProfileHeaderView(
                profile: UserProfile(
                    uid: "123",
                    name: "John Doe",
                    email: "john@example.com",
                    bio: "Spreading kindness one SIF at a time! Love connecting with people and sharing positive messages.",
                    profileImageURL: nil,
                    joinDate: Date(),
                    followersCount: 42,
                    followingCount: 28,
                    sifsSharedCount: 156,
                    totalImpactScore: 2340
                ),
                isFollowing: false,
                onFollowTap: {},
                onReportTap: {},
                onShareTap: {}
            )
        }
        .preferredColorScheme(.light)
    }
}