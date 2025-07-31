import Foundation

// MARK: - Settings migration manager
struct SettingsMigration {
    
    // MARK: - Migration result
    enum MigrationResult {
        case success
        case failed(Error)
        case noMigrationNeeded
    }
    
    // MARK: - Migration errors
    enum MigrationError: LocalizedError {
        case unsupportedVersion
        case corruptedData
        case migrationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion:
                return "Unsupported settings version"
            case .corruptedData:
                return "Settings data is corrupted"
            case .migrationFailed(let reason):
                return "Migration failed: \(reason)"
            }
        }
    }
    
    // MARK: - Check if migration is needed
    static func needsMigration(currentVersion: Int) -> Bool {
        return currentVersion < SettingsConstants.currentSettingsVersion
    }
    
    // MARK: - Perform migration
    static func migrateSettings(from data: [String: Any], currentVersion: Int) -> MigrationResult {
        // If no migration needed
        guard needsMigration(currentVersion: currentVersion) else {
            return .noMigrationNeeded
        }
        
        do {
            var migratedData = data
            
            // Perform incremental migrations
            for version in currentVersion..<SettingsConstants.currentSettingsVersion {
                migratedData = try performMigration(from: version, to: version + 1, data: migratedData)
            }
            
            return .success
        } catch {
            return .failed(error)
        }
    }
    
    // MARK: - Perform specific version migration
    private static func performMigration(from oldVersion: Int, to newVersion: Int, data: [String: Any]) throws -> [String: Any] {
        var migratedData = data
        
        switch (oldVersion, newVersion) {
        case (0, 1):
            // Migration from version 0 to 1
            migratedData = try migrateToV1(data: data)
        default:
            throw MigrationError.unsupportedVersion
        }
        
        // Update version
        migratedData["version"] = newVersion
        migratedData["lastUpdated"] = Date()
        
        return migratedData
    }
    
    // MARK: - Migration to version 1
    private static func migrateToV1(data: [String: Any]) throws -> [String: Any] {
        var migratedData = data
        
        // Ensure all required fields exist with defaults
        if migratedData["privacySettings"] == nil {
            migratedData["privacySettings"] = try SettingsDefaults.defaultPrivacySettings().asDictionary()
        }
        
        if migratedData["notificationSettings"] == nil {
            migratedData["notificationSettings"] = try SettingsDefaults.defaultNotificationSettings().asDictionary()
        }
        
        if migratedData["appearanceSettings"] == nil {
            migratedData["appearanceSettings"] = try SettingsDefaults.defaultAppearanceSettings().asDictionary()
        }
        
        if migratedData["profileSettings"] == nil {
            migratedData["profileSettings"] = try SettingsDefaults.defaultProfileSettings().asDictionary()
        }
        
        return migratedData
    }
    
    // MARK: - Backup settings before migration
    static func backupSettings(_ settings: UserSettings) {
        let key = "settings_backup_\(settings.uid)_\(Date().timeIntervalSince1970)"
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Restore from backup
    static func restoreFromBackup(uid: String) -> UserSettings? {
        let backupKeys = UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("settings_backup_\(uid)_") }
            .sorted { $0 > $1 } // Get most recent backup
        
        guard let latestBackupKey = backupKeys.first,
              let data = UserDefaults.standard.data(forKey: latestBackupKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return nil
        }
        
        return settings
    }
}

// MARK: - Encodable extension for dictionary conversion
private extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw SettingsMigration.MigrationError.corruptedData
        }
        return dictionary
    }
}