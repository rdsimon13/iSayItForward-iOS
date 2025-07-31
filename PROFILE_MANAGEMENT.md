# Profile Management System

This document describes the comprehensive Profile Management system implemented for iSayItForward iOS app.

## Overview

The Profile Management system provides users with complete control over their profile information, privacy settings, notification preferences, and account management.

## Features

### 1. Enhanced Profile View
- **Profile Image Management**: Upload, view, and edit profile images using PhotoKit
- **User Statistics**: Display of SIFs created, sent, and received
- **Bio and Display Name Editing**: In-app editing of personal information
- **Settings Navigation**: Easy access to all profile-related settings

### 2. Settings Management
- **Notification Settings**: Comprehensive notification preferences including quiet hours
- **Privacy Settings**: Profile visibility, messaging controls, online status settings
- **Account Settings**: Email/password changes, account deletion, data management

### 3. Data Management
- **Real-time Synchronization**: Automatic sync with Firebase Firestore
- **Offline Support**: Works offline with data sync when connection restored
- **Error Recovery**: Robust error handling with retry mechanisms
- **Image Caching**: Efficient image loading and caching system

## Setup Requirements

### Firebase Dependencies
The following Firebase products need to be added to your Xcode project:

1. **FirebaseAuth** ✅ (Already included)
2. **FirebaseFirestore** ✅ (Already included)
3. **FirebaseStorage** ⚠️ (Needs to be added)

### Adding FirebaseStorage

1. Open your Xcode project
2. Go to **File → Add Package Dependencies**
3. The Firebase SDK should already be included, so you need to:
   - Select your app target
   - Go to **Build Phases → Link Binary With Libraries**
   - Add **FirebaseStorage** from the Firebase package

### Permissions Required

Add these permissions to your `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>iSayItForward needs access to your photo library to set profile pictures.</string>

<key>NSCameraUsageDescription</key>
<string>iSayItForward needs access to your camera to take profile pictures.</string>
```

## Implementation Details

### Core Components

#### 1. Enhanced User Model (`User.swift`)
```swift
struct User: Codable, Identifiable {
    // Basic info
    let id: String
    let uid: String
    let name: String
    let email: String
    var displayName: String?
    var bio: String?
    var profileImageUrl: String?
    
    // Statistics
    var sifsCreated: Int
    var sifsSent: Int
    var sifsReceived: Int
    
    // Settings
    var privacySettings: PrivacySettings
    var notificationSettings: NotificationSettings
}
```

#### 2. UserDataManager (`UserDataManager.swift`)
- Handles all Firestore operations
- Provides real-time data synchronization
- Implements offline support and error recovery
- Observable object for SwiftUI integration

#### 3. ProfileImageManager (`ProfileImageManager.swift`)
- Manages profile image upload/download
- Integrates with PhotoKit for image selection
- Provides image caching and compression
- Handles Firebase Storage operations

#### 4. Settings Views
- **NotificationSettingsView**: Manage all notification preferences
- **PrivacySettingsView**: Control privacy and visibility settings
- **AccountSettingsView**: Handle account management and security

### Usage

The Profile Management system is automatically integrated into the existing app structure:

1. **Profile Tab**: Enhanced ProfileView with all new features
2. **Settings Navigation**: Seamless navigation to all settings screens
3. **Real-time Updates**: Changes are immediately synchronized across devices
4. **Offline Support**: Works offline with automatic sync when online

### Data Structure

#### Firestore Collection: `users/{uid}`
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "displayName": "string",
  "bio": "string",
  "profileImageUrl": "string",
  "sifsCreated": 0,
  "sifsSent": 0,
  "sifsReceived": 0,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "joinedDate": "timestamp",
  "privacySettings": {
    "profileVisibility": "everyone|friends_only|nobody",
    "allowsMessagesFromStrangers": true,
    "showOnlineStatus": true,
    "showLastSeen": true,
    "allowProfileImageDownload": true
  },
  "notificationSettings": {
    "pushNotificationsEnabled": true,
    "emailNotificationsEnabled": true,
    "newSIFNotifications": true,
    "scheduledSIFReminders": true,
    "friendRequestNotifications": true,
    "marketingNotifications": false,
    "soundEnabled": true,
    "vibrationEnabled": true,
    "quietHoursEnabled": false,
    "quietHoursStart": "22:00",
    "quietHoursEnd": "08:00"
  }
}
```

#### Firebase Storage Structure
```
profile_images/{uid}.jpg
```

## Error Handling

The system includes comprehensive error handling:

- **Network Errors**: Automatic retry with exponential backoff
- **Authentication Errors**: Clear user feedback and re-authentication flows
- **Validation Errors**: Input validation with helpful error messages
- **Storage Errors**: Fallback mechanisms for image operations

## Performance Considerations

- **Image Caching**: NSCache for efficient image loading
- **Real-time Listeners**: Optimized Firestore queries
- **Offline Support**: Local data persistence
- **Image Compression**: Automatic image optimization before upload

## Future Enhancements

Potential areas for future development:

1. **Social Features**: Friend connections and sharing
2. **Advanced Privacy**: Granular privacy controls
3. **Data Export**: Complete user data download
4. **Themes**: Customizable app themes
5. **Analytics**: User engagement metrics

## Testing

The system includes comprehensive error states and loading indicators. Test scenarios:

1. **Offline Mode**: Test all functionality without internet
2. **Image Upload**: Test various image sizes and formats
3. **Settings Persistence**: Verify settings are saved correctly
4. **Error Recovery**: Test error scenarios and recovery mechanisms

## Support

For issues or questions about the Profile Management system, refer to the inline documentation and error messages provided throughout the implementation.