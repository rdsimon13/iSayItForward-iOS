# Content Safety & Reporting System

## Overview

This implementation provides a comprehensive content safety and reporting system for the iSayItForward iOS app. The system includes content reporting, moderation tools, and user blocking functionality.

## Architecture

### Core Components

1. **Data Models** (`ReportModel.swift`)
   - `Report`: Stores content reports with category, status, and moderation info
   - `BlockedUser`: Tracks blocked user relationships
   - `ReportCategory`: Enumeration of report types
   - `ReportStatus`: Report lifecycle states

2. **Business Logic** (`ContentSafetyManager.swift`)
   - Thread-safe `@MainActor` class with `ObservableObject`
   - Handles all Firebase operations for reports and blocking
   - Provides content filtering capabilities
   - Manages moderator permissions

3. **User Interface Components**
   - `ReportView`: Content reporting interface
   - `ModeratorView`: Report management dashboard
   - `ReportDetailView`: Individual report review
   - `BlockedUsersView`: Blocked users management
   - `BlockUserActionView`: User blocking interface

## Features

### Content Reporting

Users can report inappropriate content through:
- Report button in SIF detail view (toolbar menu)
- Multiple report categories (spam, harassment, inappropriate content, etc.)
- Optional detailed reason input
- Form validation and submission

### Content Moderation

Moderators can:
- View all reports with filtering by status
- Review individual reports with full details
- Update report status (pending → under review → resolved/dismissed)
- Add moderator notes and comments
- Track moderation actions for audit

### User Blocking

Users can:
- Block other users from SIF detail view
- View and manage blocked users list
- Unblock users at any time
- Content from blocked users is automatically filtered

### Content Filtering

The system automatically:
- Filters out content from blocked users in SIF lists
- Applies filtering in `MySIFsView` and other content views
- Maintains performance with efficient filtering

## Integration Points

### Existing Views Modified

1. **SIFDetailView**: Added report and block user actions in toolbar menu
2. **ProfileView**: Added navigation to blocked users and moderator tools
3. **MySIFsView**: Integrated content filtering for blocked users
4. **User Model**: Extended with moderator flag and blocked users array

### Firebase Collections

The system uses these Firestore collections:
- `reports`: Store content reports
- `blockedUsers`: Track user blocking relationships
- `moderatorActions`: Audit trail for moderation actions
- `users`: Extended with `isModerator` and `blockedUsers` fields

## Usage

### For Regular Users

1. **Report Content**:
   - Open any SIF detail view
   - Tap the menu button (three dots) in top right
   - Select "Report Content"
   - Choose category and provide details
   - Submit report

2. **Block Users**:
   - From SIF detail view, tap menu → "Block User"
   - Optionally provide reason
   - Confirm blocking action

3. **Manage Blocked Users**:
   - Go to Profile → "Blocked Users"
   - View blocked users list
   - Tap "Unblock" to remove blocks

### For Moderators

1. **Access Moderation Tools**:
   - Ensure user has `isModerator: true` in Firestore
   - Go to Profile → "Content Moderation"

2. **Review Reports**:
   - View reports filtered by status
   - Tap any report to see details
   - Add notes and take actions

3. **Moderate Content**:
   - Mark reports as "Under Review"
   - Resolve violations or dismiss false reports
   - Add moderator notes for context

## Error Handling

The system includes comprehensive error handling:
- User-friendly error messages
- Network failure recovery
- Authentication state validation
- Input validation and sanitization

## Security Considerations

- All operations require user authentication
- Moderator actions are logged for audit
- User blocking is one-way (blocker controls relationship)
- Report submission prevents spam with validation
- Content filtering happens client-side for performance

## Testing

Use `ContentSafetyTestData.swift` for:
- Sample data for development
- Testing content filtering
- Demonstrating report categories
- Mock blocked user scenarios

Access the demo view through Profile → "Content Safety Demo" (DEBUG builds only).

## Future Enhancements

Potential improvements:
- Automated content scanning
- Report abuse prevention
- Moderator permissions levels
- Content appeal process
- Analytics and reporting dashboards
- Push notifications for moderators