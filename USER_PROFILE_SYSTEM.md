# User Profile Viewing System

## Overview

The User Profile Viewing system allows users to view and interact with other users' profiles within the iSayItForward app. This comprehensive system includes profile information, statistics, shared messages, and social features.

## Components

### Core Services
- **UserProfileService.swift**: Handles all Firebase operations for user profiles, including data fetching, follow/unfollow actions, reporting, and caching.

### ViewModels
- **UserProfileViewModel.swift**: Manages state, business logic, and user interactions for profile views.

### Main Views
- **UserProfileView.swift**: The main profile viewing interface with loading states and error handling.
- **ProfileHeaderView.swift**: Reusable profile header component with user info and action buttons.
- **ProfileStatisticsView.swift**: Displays impact statistics and community metrics.
- **UserMessageListView.swift**: Shows user's shared messages with pagination.
- **SharedProfileActionSheet.swift**: Handles profile sharing and user reporting interfaces.

## Features

### Profile Information
- User avatar (with initials fallback)
- Name, bio, and member since date
- Impact statistics (SIFs shared, followers, following, impact score)
- Community rank and engagement metrics

### Social Features
- Follow/unfollow functionality
- Follower and following counts
- Profile sharing via multiple channels
- User reporting system

### Message Display
- Public SIF messages from the user
- Pagination for performance
- Message preview with recipient count
- Scheduled message indicators

### Integration Points
- **SIFDetailView**: Added author information with profile navigation
- **HomeView**: Added demo profile access for testing

## Usage

### Navigating to User Profiles

1. **From SIF Details**: When viewing a SIF created by another user, tap the author row to view their profile.

2. **From Home Screen**: Use the "Community Profiles" button to access a demo profile.

3. **Programmatically**: Present UserProfileView with a user UID:
```swift
UserProfileView(userUID: "user-uid-here")
```

### Data Requirements

The system expects the following Firestore collections:

#### Users Collection (`users`)
```javascript
{
  name: "User Name",
  email: "user@example.com",
  bio: "User bio (optional)",
  profileImageURL: "https://... (optional)",
  joinDate: Timestamp,
  followersCount: 0,
  followingCount: 0,
  sifsSharedCount: 0,
  totalImpactScore: 0
}
```

#### SIFs Collection (`sifs`)
```javascript
{
  authorUid: "user-uid",
  recipients: ["email1", "email2"],
  subject: "Message subject",
  message: "Message content",
  createdDate: Timestamp,
  scheduledDate: Timestamp,
  isPublic: true // Required for profile viewing
}
```

#### Follows Collection (`follows`)
```javascript
{
  followerUID: "follower-uid",
  followingUID: "following-uid",
  createdDate: Timestamp
}
```

## Customization

### Styling
All components use the existing app theme:
- `Color.brandDarkBlue` for primary text and accents
- `Color.brandYellow` for highlights and icons
- `Color.mainAppGradient` for backgrounds
- Consistent with existing button styles and card layouts

### Statistics
The system calculates several derived metrics:
- **Engagement Rate**: Impact score relative to followers
- **Average Impact**: Impact per SIF shared
- **Community Rank**: Based on total impact score

### Error Handling
- Network errors with retry functionality
- User not found scenarios
- Authentication requirements
- Loading states throughout the interface

## Testing

### Demo Profile
A demo profile is accessible from the home screen for testing purposes. The demo uses the UID "demo-user-123".

### Test Data
For full functionality, ensure test users have:
- Complete profile information
- Some public SIF messages
- Follow relationships with other users

## Performance Considerations

### Caching
- User profiles are cached after first load
- Cache can be cleared or specific profiles removed
- Automatic cache invalidation on profile updates

### Pagination
- Messages load 20 at a time by default
- "Load More" functionality for additional messages
- Optimized for smooth scrolling

### Analytics
- Profile views are tracked automatically
- No tracking of own profile views
- Anonymous analytics for usage patterns

## Future Enhancements

Potential improvements for the system:
- Search functionality for finding users
- Block user functionality
- Profile editing capabilities
- Enhanced statistics and achievements
- Image upload for profile pictures
- Push notifications for follows
- Activity feeds showing user interactions