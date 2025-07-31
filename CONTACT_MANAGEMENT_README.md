# Contact Management System for iSayItForward iOS

A comprehensive contact management system that integrates seamlessly with the existing iSayItForward iOS application, providing robust contact management, privacy controls, and SIF integration.

## Features Overview

### 🏗️ Core Infrastructure
- **CoreData Integration**: Robust local storage with Contact, ContactGroup, and ContactActivity entities
- **Firebase Synchronization**: Real-time cloud sync with conflict resolution
- **MVVM Architecture**: Clean separation of concerns following app patterns
- **Comprehensive Error Handling**: User-friendly error messages and recovery options

### 👥 Contact Management
- **Add/Edit/Delete Contacts**: Full CRUD operations with validation
- **Contact Profiles**: Comprehensive contact information including photos, notes, and tags
- **Advanced Search**: Multi-field search across names, emails, phones, and notes
- **Contact Activities**: Track all interactions and SIF history
- **Batch Operations**: Bulk import, export, and management capabilities

### 🔒 Privacy & Security
- **Privacy Levels**: Three-tier privacy system (Normal, Restricted, Private)
- **Contact Blocking**: Block unwanted contacts with activity tracking
- **Data Encryption**: Configurable encryption for sensitive contact fields
- **Access Controls**: Granular permissions and privacy settings
- **Biometric Protection**: Optional biometric access for sensitive contacts

### 📁 Organization & Groups
- **System Groups**: Built-in Favorites, Recent, and Blocked groups
- **Custom Groups**: Create and manage custom contact categories
- **Smart Tags**: Flexible tagging system for advanced organization
- **Visual Organization**: Color-coded groups and visual indicators

### 🔄 Integration Features
- **SIF Integration**: Seamless contact selection for SIF creation
- **Activity Tracking**: Complete history of SIF sending/receiving
- **Contact Picker**: Advanced multi-select contact picker with filtering
- **Real-time Updates**: Live contact status and availability indicators

### 📲 Import/Export
- **Device Contacts Import**: Selective or bulk import from device contacts
- **Multiple Export Formats**: CSV, JSON, and vCard export options
- **Smart Duplicate Detection**: Automatic duplicate prevention during import
- **Permission Management**: Proper contacts permission handling

### 📊 Analytics & Insights
- **Contact Analytics**: Comprehensive statistics and insights
- **Usage Patterns**: Track contact interaction patterns
- **Privacy Distribution**: Visualize privacy level distribution
- **Smart Recommendations**: AI-powered contact management suggestions

## Architecture

### Data Models

#### Contact
```swift
struct Contact {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String?
    var notes: String?
    var isBlocked: Bool
    var isFavorite: Bool
    var privacyLevel: ContactPrivacyLevel
    var tags: [String]
    var avatarImageData: Data?
    // ... additional properties
}
```

#### ContactGroup
```swift
struct ContactGroup {
    let id: UUID
    var name: String
    var colorHex: String
    var isSystemGroup: Bool
    // ... additional properties
}
```

#### ContactActivity
```swift
struct ContactActivity {
    let id: UUID
    var activityType: ContactActivityType
    var activityDate: Date
    var sifId: String?
    var notes: String?
}
```

### Core Services

#### ContactManager
- Central service for all contact operations
- Manages CRUD operations with CoreData
- Handles Firebase synchronization
- Provides search and filtering capabilities
- Manages contact activities and relationships

#### FirebaseContactService
- Real-time cloud synchronization
- Conflict resolution and merge strategies
- Offline/online state management
- Batch operations for efficiency

#### DeviceContactsImportService
- Permission management for device contacts
- Selective and bulk import capabilities
- Duplicate detection and prevention
- Progress tracking and error handling

### UI Components

#### Views
- **ContactListView**: Main contact listing with search and actions
- **ContactDetailView**: Comprehensive contact viewing and editing
- **AddContactView**: Contact creation with validation and media support
- **ContactPickerView**: Advanced multi-select contact picker
- **ContactSettingsView**: Privacy and sync configuration
- **ContactDashboardView**: Analytics and management overview

#### Specialized Components
- **ContactAvatarView**: Reusable avatar display component
- **ContactRowView**: Consistent contact list item
- **TagView**: Interactive tag management
- **ActivityRowView**: Contact activity display

## Installation & Setup

### Prerequisites
- iOS 16.0+
- Xcode 14.0+
- Firebase project with Firestore enabled
- Contacts framework permissions

### Integration Steps

1. **Add to Xcode Project**
   ```
   Add all Contact*.swift files to your project
   Ensure ContactDataModel.xcdatamodeld is included in your target
   ```

2. **Update App Delegate**
   ```swift
   import CoreData
   
   // Add PersistenceManager to app initialization
   @StateObject private var persistenceManager = PersistenceManager.shared
   ```

3. **Configure Permissions**
   ```xml
   <!-- Add to Info.plist -->
   <key>NSContactsUsageDescription</key>
   <string>This app needs access to contacts to import them for SIF messaging.</string>
   ```

4. **Firebase Configuration**
   ```
   Ensure Firebase is properly configured with Firestore
   Contact synchronization requires authenticated users
   ```

## Usage Examples

### Basic Contact Operations

```swift
// Create a new contact
let contact = Contact(
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    phoneNumber: "+1234567890"
)

// Add to contact manager
contactManager.addContact(contact)

// Search contacts
let results = contactManager.searchContacts(query: "john")

// Update contact
var updatedContact = contact
updatedContact.isFavorite = true
contactManager.updateContact(updatedContact)
```

### SIF Integration

```swift
// Create SIF with selected contacts
let selectedContacts = [contact1, contact2, contact3]
let sif = SIFContactHelper.createSIFWithContacts(
    selectedContacts,
    subject: "Hello!",
    message: "How are you doing?"
)

// Record activity
SIFContactHelper.recordSIFSentActivity(
    to: selectedContacts,
    sifId: sif.id,
    contactManager: contactManager
)
```

### Cloud Synchronization

```swift
// Sync all contacts to cloud
await contactManager.syncAllContactsToCloud()

// Sync from cloud
await contactManager.syncAllContactsFromCloud()

// Real-time sync is automatic when user is authenticated
```

### Device Import

```swift
// Import all device contacts
let importService = DeviceContactsImportService(contactManager: contactManager)
await importService.importAllContacts()

// Selective import
let deviceContacts = try await importService.fetchDeviceContactsForSelection()
await importService.importSelectedContacts(selectedContacts)
```

## Privacy & Security

### Privacy Levels
- **Normal**: Standard contact visibility and access
- **Restricted**: Limited visibility with enhanced privacy
- **Private**: Maximum privacy with optional encryption

### Data Protection
- All contact data stored locally with CoreData
- Cloud sync uses Firebase security rules
- Optional field-level encryption for sensitive data
- Biometric protection for high-security contacts

### Permissions
- Explicit contacts permission requests
- Granular privacy controls per contact
- User-controlled sync and sharing options

## Testing

### Unit Tests
Comprehensive test suite covering:
- Contact CRUD operations
- Search and filtering functionality
- Privacy level management
- Activity tracking
- Data model validation

### Test Coverage
- ContactManager functionality
- Contact model operations
- Search algorithms
- Privacy controls
- Activity tracking

## Performance Considerations

### Optimization Features
- Lazy loading for large contact lists
- Efficient search indexing
- Background sync operations
- Image compression for avatars
- Smart caching strategies

### Scalability
- Supports thousands of contacts
- Efficient CoreData relationships
- Optimized Firebase queries
- Progressive loading for UI

## Dependencies

### Required Frameworks
- SwiftUI (iOS 16.0+)
- CoreData
- Contacts
- Firebase/Firestore
- Firebase/Auth

### Optional Frameworks
- MessageUI (for email export)
- CryptoKit (for encryption)
- LocalAuthentication (for biometric access)

## Roadmap

### Planned Features
- [ ] Advanced contact relationships
- [ ] Smart contact suggestions
- [ ] Contact synchronization across platforms
- [ ] Enhanced privacy controls
- [ ] Integration with calendar events
- [ ] Contact backup and restore
- [ ] Advanced analytics dashboard

### Performance Improvements
- [ ] Contact indexing optimization
- [ ] Memory usage optimization for large datasets
- [ ] Background sync improvements
- [ ] Enhanced offline support

## Contributing

### Code Style
- Follow existing SwiftUI and MVVM patterns
- Comprehensive documentation required
- Unit tests for all new functionality
- Privacy-first approach to all features

### Pull Request Process
1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request with description

## License

This Contact Management System is part of the iSayItForward iOS application and follows the same licensing terms.

## Support

For technical support or feature requests, please refer to the main iSayItForward repository issues section.