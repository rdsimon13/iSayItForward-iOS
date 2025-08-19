# Report UI Implementation Guide

## Overview
This implementation provides a system-wide report UI that matches the provided mockups and follows iOS design guidelines.

## Files Added
1. `ReportContentView.swift` - Main report modal with two-screen flow
2. `ReportOverlayModifier.swift` - ViewModifier and global manager for system-wide access
3. `TestReportView.swift` - Test view for development/demonstration
4. `ReportUIDemo.swift` - Comprehensive demo view showing all features

## Files Modified
1. `iSayItForwardApp.swift` - Added GlobalReportOverlay to app root
2. `AppDelegate.swift` - Added UserNotifications framework setup
3. `iSayItForward-Info.plist` - Added notification permissions
4. `SIFDetailView.swift` - Added report button example
5. `HomeView.swift` - Added report button example

## Build Configuration Required

### 1. Add New Files to Xcode Project
The following Swift files need to be added to the Xcode project:
- ReportContentView.swift
- ReportOverlayModifier.swift
- TestReportView.swift (optional, for testing)
- ReportUIDemo.swift (optional, for demonstration)

**Steps:**
1. Open the project in Xcode
2. Right-click on the project navigator
3. Select "Add Files to 'iSayItForward'"
4. Select the new Swift files
5. Ensure they are added to the main app target

### 2. UserNotifications Framework
The UserNotifications framework is now imported in AppDelegate.swift. Ensure this framework is linked:
1. Select the project in Xcode
2. Go to Build Phases > Link Binary With Libraries
3. Add UserNotifications.framework if not already present

## UI Features Implemented

### ✅ Semi-transparent Dark Overlay
- 40% black opacity (`Color.black.opacity(0.4)`)
- Full screen coverage with `ignoresSafeArea()`
- Tap-to-dismiss functionality
- Proper accessibility labels

### ✅ Centered White Modal Card
- White background (`Color.white`)
- 16pt rounded corners (`RoundedRectangle(cornerRadius: 16)`)
- Appropriate shadow (`shadow(color: .black.opacity(0.2), radius: 10, y: 5)`)
- 32pt horizontal padding for proper centering

### ✅ Report Content Header
- "Report Content" title using `.title2` font
- X close button with circular background
- Proper accessibility support
- Consistent with app's brand colors

### ✅ Report Reasons List
- 6 predefined report reasons (Spam, Harassment, etc.)
- Chevron indicators on the right
- Dividers between items
- Proper touch feedback
- Animated transitions

### ✅ Follow-up Details Screen
- Back navigation with chevron left
- Selected reason display
- Text editor for additional details
- Submit button with loading state
- Proper keyboard handling

### ✅ System-wide Access
- `ReportManager.shared` singleton for global access
- `reportOverlay(isPresented:)` ViewModifier for local use
- `GlobalReportOverlay` for app-level integration
- `ReportButton` component for easy integration

## Usage Examples

### Method 1: ViewModifier (Local)
```swift
struct MyView: View {
    @State private var showReport = false
    
    var body: some View {
        // Your view content
        .reportOverlay(isPresented: $showReport)
        .toolbar {
            ToolbarItem {
                Button("Report") { showReport = true }
            }
        }
    }
}
```

### Method 2: Global Manager
```swift
Button("Report Content") {
    ReportManager.shared.showReport(context: "Specific content")
}
```

### Method 3: Quick Report Button
```swift
ReportButton(context: "User post #123")
```

## Design System Compliance

### Colors
- Primary text: `Theme.brandTeal` (#2e385c)
- Secondary text: `.secondary` system color
- Accent: `Theme.brandGold` (#ffac04)
- Background: `Color.white`
- Overlay: `Color.black.opacity(0.4)`

### Typography
- Headers: `.title2` with `.semibold` weight
- Body text: `.body` font
- Captions: `.caption` for secondary info

### Spacing & Layout
- Card padding: 24pt horizontally, 20pt vertically
- Component spacing: 16-20pt between major elements
- Button heights: Consistent with existing `PrimaryActionButtonStyle`

### Animations
- Modal presentation: `.easeInOut(duration: 0.3)`
- Scale effect: 0.8 to 1.0 for modal appearance
- Smooth transitions between screens

## Accessibility Features
- Proper accessibility labels and hints
- Voice Over support
- Large text support via system fonts
- High contrast compatibility
- Keyboard navigation support

## Testing
Use `ReportUIDemo.swift` to test all functionality:
1. Launch report modal
2. Navigate through reason selection
3. Fill out details form
4. Test submission flow
5. Test global manager access

## Notes
- The implementation follows iOS Human Interface Guidelines
- All animations and transitions are smooth and responsive
- The UI is fully compatible with both iPhone and iPad
- The design matches the existing app's visual style
- Error handling is included for edge cases
