import Foundation
import SwiftUI

// MARK: - Appearance settings model
struct AppearanceSettings: Codable {
    var theme: AppTheme
    var textSize: TextSize
    var layoutDensity: LayoutDensity
    var reducedMotion: Bool
    var highContrast: Bool
    var colorBlindnessSupport: ColorBlindnessType
    var preferredLanguage: String
    var use24HourFormat: Bool
    var showPreviewImages: Bool
    var compactMode: Bool
    
    init() {
        self.theme = .system
        self.textSize = .medium
        self.layoutDensity = .comfortable
        self.reducedMotion = false
        self.highContrast = false
        self.colorBlindnessSupport = .none
        self.preferredLanguage = "en"
        self.use24HourFormat = false
        self.showPreviewImages = true
        self.compactMode = false
    }
}

// MARK: - App theme options
enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Text size options
enum TextSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

// MARK: - Layout density options
enum LayoutDensity: String, Codable, CaseIterable {
    case compact = "compact"
    case comfortable = "comfortable"
    case spacious = "spacious"
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .comfortable: return "Comfortable"
        case .spacious: return "Spacious"
        }
    }
}

// MARK: - Color blindness support
enum ColorBlindnessType: String, Codable, CaseIterable {
    case none = "none"
    case deuteranopia = "deuteranopia"
    case protanopia = "protanopia"
    case tritanopia = "tritanopia"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .deuteranopia: return "Deuteranopia"
        case .protanopia: return "Protanopia"
        case .tritanopia: return "Tritanopia"
        }
    }
}