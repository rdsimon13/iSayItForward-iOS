import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Settings service for data management
@MainActor
class SettingsService: ObservableObject {
    
    // MARK: - Published properties
    @Published var userSettings: UserSettings?
    @Published var isLoading = false
    @Published var error: SettingsError?
    @Published var lastSyncDate: Date?
    
    // MARK: - Private properties
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var settingsCache: [String: UserSettings] = [:]
    
    // MARK: - Singleton instance
    static let shared = SettingsService()
    
    private init() {
        setupSettingsListener()
    }
    
    // MARK: - Settings errors
    enum SettingsError: LocalizedError {
        case userNotAuthenticated
        case networkError(Error)
        case validationError([SettingsValidation.ValidationError])
        case migrationError(Error)
        case saveError(Error)
        case loadError(Error)
        
        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return "User is not authenticated"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .validationError(let errors):
                return "Validation errors: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
            case .migrationError(let error):
                return "Migration error: \(error.localizedDescription)"
            case .saveError(let error):
                return "Save error: \(error.localizedDescription)"
            case .loadError(let error):
                return "Load error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Load user settings
    func loadSettings() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw SettingsError.userNotAuthenticated
        }
        
        isLoading = true
        error = nil
        
        do {
            // Check cache first
            if let cachedSettings = settingsCache[uid] {
                userSettings = cachedSettings
                isLoading = false
                return
            }
            
            let document = try await db.collection(SettingsConstants.userSettingsCollection)
                .document(uid)
                .getDocument()
            
            if document.exists, let data = document.data() {
                // Check if migration is needed
                let currentVersion = data["version"] as? Int ?? 0
                
                if SettingsMigration.needsMigration(currentVersion: currentVersion) {
                    let migrationResult = SettingsMigration.migrateSettings(from: data, currentVersion: currentVersion)
                    
                    switch migrationResult {
                    case .success:
                        // Settings migrated successfully, reload
                        try await loadSettings()
                        return
                    case .failed(let error):
                        throw SettingsError.migrationError(error)
                    case .noMigrationNeeded:
                        break
                    }
                }
                
                // Parse settings
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let settings = try JSONDecoder().decode(UserSettings.self, from: jsonData)
                
                // Cache and update
                settingsCache[uid] = settings
                userSettings = settings
                lastSyncDate = Date()
                
            } else {
                // Create default settings for new user
                let defaultSettings = SettingsDefaults.safeDefaultSettings(for: uid)
                try await saveSettings(defaultSettings)
                userSettings = defaultSettings
            }
            
        } catch {
            self.error = SettingsError.loadError(error)
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Save user settings
    func saveSettings(_ settings: UserSettings) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw SettingsError.userNotAuthenticated
        }
        
        // Validate settings
        let validationErrors = SettingsValidation.validateUserSettings(settings)
        if !validationErrors.isEmpty {
            throw SettingsError.validationError(validationErrors)
        }
        
        isLoading = true
        error = nil
        
        do {
            // Backup before saving
            if let currentSettings = userSettings {
                SettingsMigration.backupSettings(currentSettings)
            }
            
            // Update version and timestamp
            var updatedSettings = settings
            updatedSettings.version = SettingsConstants.currentSettingsVersion
            updatedSettings.lastUpdated = Date()
            
            // Convert to dictionary for Firestore
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(updatedSettings)
            let dictionary = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            
            // Save to Firestore
            try await db.collection(SettingsConstants.userSettingsCollection)
                .document(settings.uid)
                .setData(dictionary)
            
            // Update cache and local state
            settingsCache[settings.uid] = updatedSettings
            userSettings = updatedSettings
            lastSyncDate = Date()
            
            // Save sync date to UserDefaults
            UserDefaults.standard.set(Date(), forKey: SettingsConstants.lastSyncDateKey)
            
        } catch {
            self.error = SettingsError.saveError(error)
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Update specific settings section
    func updateProfileSettings(_ profileSettings: ProfileSettings) async throws {
        guard var settings = userSettings else { return }
        settings.profileSettings = profileSettings
        try await saveSettings(settings)
    }
    
    func updatePrivacySettings(_ privacySettings: PrivacySettings) async throws {
        guard var settings = userSettings else { return }
        settings.privacySettings = privacySettings
        try await saveSettings(settings)
    }
    
    func updateNotificationSettings(_ notificationSettings: NotificationSettings) async throws {
        guard var settings = userSettings else { return }
        settings.notificationSettings = notificationSettings
        try await saveSettings(settings)
    }
    
    func updateAppearanceSettings(_ appearanceSettings: AppearanceSettings) async throws {
        guard var settings = userSettings else { return }
        settings.appearanceSettings = appearanceSettings
        try await saveSettings(settings)
    }
    
    // MARK: - Reset settings
    func resetToDefaults() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw SettingsError.userNotAuthenticated
        }
        
        let defaultSettings = SettingsDefaults.factoryReset(preservingUID: uid)
        try await saveSettings(defaultSettings)
    }
    
    // MARK: - Setup real-time listener
    private func setupSettingsListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self, let uid = user?.uid else {
                self?.userSettings = nil
                return
            }
            
            // Listen for real-time updates
            self.db.collection(SettingsConstants.userSettingsCollection)
                .document(uid)
                .addSnapshotListener { [weak self] documentSnapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.error = SettingsError.networkError(error)
                        return
                    }
                    
                    guard let document = documentSnapshot,
                          document.exists,
                          let data = document.data() else { return }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let settings = try JSONDecoder().decode(UserSettings.self, from: jsonData)
                        
                        DispatchQueue.main.async {
                            self.settingsCache[uid] = settings
                            self.userSettings = settings
                            self.lastSyncDate = Date()
                        }
                    } catch {
                        self.error = SettingsError.loadError(error)
                    }
                }
        }
    }
    
    // MARK: - Cache management
    func clearCache() {
        settingsCache.removeAll()
    }
    
    // MARK: - Offline support
    func getOfflineSettings() -> UserSettings? {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = UserDefaults.standard.data(forKey: SettingsConstants.offlineSettingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data),
              settings.uid == uid else {
            return nil
        }
        return settings
    }
    
    func saveOfflineSettings(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: SettingsConstants.offlineSettingsKey)
        }
    }
}