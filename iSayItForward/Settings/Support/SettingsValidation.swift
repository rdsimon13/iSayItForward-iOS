import Foundation

// MARK: - Settings validation utility
struct SettingsValidation {
    
    // MARK: - Validation errors
    enum ValidationError: LocalizedError {
        case displayNameTooLong
        case displayNameEmpty
        case bioTooLong
        case invalidEmail
        case invalidPhoneNumber
        case tooManySkills
        case tooManyExpertise
        case invalidWebsiteURL
        case invalidQuietHours
        
        var errorDescription: String? {
            switch self {
            case .displayNameTooLong:
                return "Display name must be \(SettingsConstants.maxDisplayNameLength) characters or less"
            case .displayNameEmpty:
                return "Display name cannot be empty"
            case .bioTooLong:
                return "Bio must be \(SettingsConstants.maxBioLength) characters or less"
            case .invalidEmail:
                return "Please enter a valid email address"
            case .invalidPhoneNumber:
                return "Please enter a valid phone number"
            case .tooManySkills:
                return "You can add up to \(SettingsConstants.maxSkillsCount) skills"
            case .tooManyExpertise:
                return "You can add up to \(SettingsConstants.maxExpertiseCount) areas of expertise"
            case .invalidWebsiteURL:
                return "Please enter a valid website URL"
            case .invalidQuietHours:
                return "Invalid quiet hours format"
            }
        }
    }
    
    // MARK: - Profile settings validation
    static func validateProfileSettings(_ settings: ProfileSettings) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if settings.displayName.isEmpty {
            errors.append(.displayNameEmpty)
        } else if settings.displayName.count > SettingsConstants.maxDisplayNameLength {
            errors.append(.displayNameTooLong)
        }
        
        if settings.bio.count > SettingsConstants.maxBioLength {
            errors.append(.bioTooLong)
        }
        
        if !settings.website.isEmpty && !isValidURL(settings.website) {
            errors.append(.invalidWebsiteURL)
        }
        
        if !settings.phoneNumber.isEmpty && !isValidPhoneNumber(settings.phoneNumber) {
            errors.append(.invalidPhoneNumber)
        }
        
        if settings.skills.count > SettingsConstants.maxSkillsCount {
            errors.append(.tooManySkills)
        }
        
        if settings.expertise.count > SettingsConstants.maxExpertiseCount {
            errors.append(.tooManyExpertise)
        }
        
        return errors
    }
    
    // MARK: - Notification settings validation
    static func validateNotificationSettings(_ settings: NotificationSettings) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if !isValidTimeFormat(settings.quietHoursStart) || !isValidTimeFormat(settings.quietHoursEnd) {
            errors.append(.invalidQuietHours)
        }
        
        return errors
    }
    
    // MARK: - Complete settings validation
    static func validateUserSettings(_ settings: UserSettings) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        errors.append(contentsOf: validateProfileSettings(settings.profileSettings))
        errors.append(contentsOf: validateNotificationSettings(settings.notificationSettings))
        
        return errors
    }
    
    // MARK: - Helper validation methods
    private static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    private static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^[\\+]?[1-9][\\d]{0,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phoneNumber)
    }
    
    private static func isValidTimeFormat(_ time: String) -> Bool {
        let timeRegex = "^([01]?[0-9]|2[0-3]):[0-5][0-9]$"
        let timeTest = NSPredicate(format: "SELF MATCHES %@", timeRegex)
        return timeTest.evaluate(with: time)
    }
    
    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
}