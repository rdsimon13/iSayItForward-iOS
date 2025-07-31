import Foundation
import SwiftUI

// MARK: - Appearance settings view model
@MainActor
class AppearanceSettingsViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var theme: AppTheme = .system
    @Published var textSize: TextSize = .medium
    @Published var layoutDensity: LayoutDensity = .comfortable
    @Published var reducedMotion = false
    @Published var highContrast = false
    @Published var colorBlindnessSupport: ColorBlindnessType = .none
    @Published var preferredLanguage = "en"
    @Published var use24HourFormat = false
    @Published var showPreviewImages = true
    @Published var compactMode = false
    
    // UI state
    @Published var showingLanguagePicker = false
    @Published var showingThemePreview = false
    @Published var previewTheme: AppTheme?
    
    // MARK: - Private properties
    private let settingsService = SettingsService.shared
    private let availableLanguages = [
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文"),
        ("ja", "日本語")
    ]
    
    // MARK: - Update settings
    func updateSettings(_ settings: AppearanceSettings) {
        theme = settings.theme
        textSize = settings.textSize
        layoutDensity = settings.layoutDensity
        reducedMotion = settings.reducedMotion
        highContrast = settings.highContrast
        colorBlindnessSupport = settings.colorBlindnessSupport
        preferredLanguage = settings.preferredLanguage
        use24HourFormat = settings.use24HourFormat
        showPreviewImages = settings.showPreviewImages
        compactMode = settings.compactMode
    }
    
    // MARK: - Create settings object
    func createAppearanceSettings() -> AppearanceSettings {
        var settings = AppearanceSettings()
        settings.theme = theme
        settings.textSize = textSize
        settings.layoutDensity = layoutDensity
        settings.reducedMotion = reducedMotion
        settings.highContrast = highContrast
        settings.colorBlindnessSupport = colorBlindnessSupport
        settings.preferredLanguage = preferredLanguage
        settings.use24HourFormat = use24HourFormat
        settings.showPreviewImages = showPreviewImages
        settings.compactMode = compactMode
        return settings
    }
    
    // MARK: - Save changes
    func saveChanges() async {
        let appearanceSettings = createAppearanceSettings()
        
        do {
            try await settingsService.updateAppearanceSettings(appearanceSettings)
        } catch {
            // Handle error - would be passed up to parent view model
        }
    }
    
    // MARK: - Theme management
    func setTheme(_ newTheme: AppTheme) async {
        theme = newTheme
        await saveChanges()
    }
    
    func previewThemeTemporarily(_ tempTheme: AppTheme) {
        previewTheme = tempTheme
        showingThemePreview = true
        
        // Auto-dismiss preview after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.dismissThemePreview()
        }
    }
    
    func applyPreviewedTheme() async {
        if let previewTheme = previewTheme {
            await setTheme(previewTheme)
        }
        dismissThemePreview()
    }
    
    func dismissThemePreview() {
        previewTheme = nil
        showingThemePreview = false
    }
    
    // MARK: - Text size management
    func setTextSize(_ newSize: TextSize) async {
        textSize = newSize
        await saveChanges()
    }
    
    func increaseTextSize() async {
        switch textSize {
        case .small:
            await setTextSize(.medium)
        case .medium:
            await setTextSize(.large)
        case .large:
            await setTextSize(.extraLarge)
        case .extraLarge:
            break // Already at maximum
        }
    }
    
    func decreaseTextSize() async {
        switch textSize {
        case .small:
            break // Already at minimum
        case .medium:
            await setTextSize(.small)
        case .large:
            await setTextSize(.medium)
        case .extraLarge:
            await setTextSize(.large)
        }
    }
    
    // MARK: - Layout density management
    func setLayoutDensity(_ newDensity: LayoutDensity) async {
        layoutDensity = newDensity
        await saveChanges()
    }
    
    // MARK: - Accessibility features
    func toggleReducedMotion() async {
        reducedMotion.toggle()
        await saveChanges()
    }
    
    func toggleHighContrast() async {
        highContrast.toggle()
        await saveChanges()
    }
    
    func setColorBlindnessSupport(_ support: ColorBlindnessType) async {
        colorBlindnessSupport = support
        await saveChanges()
    }
    
    // MARK: - Language and localization
    func setLanguage(_ languageCode: String) async {
        preferredLanguage = languageCode
        await saveChanges()
    }
    
    func toggle24HourFormat() async {
        use24HourFormat.toggle()
        await saveChanges()
    }
    
    // MARK: - Display preferences
    func togglePreviewImages() async {
        showPreviewImages.toggle()
        await saveChanges()
    }
    
    func toggleCompactMode() async {
        compactMode.toggle()
        await saveChanges()
    }
    
    // MARK: - Preset configurations
    func applyAccessibilityOptimized() async {
        textSize = .large
        layoutDensity = .spacious
        reducedMotion = true
        highContrast = true
        compactMode = false
        showPreviewImages = false
        
        await saveChanges()
    }
    
    func applyPerformanceOptimized() async {
        theme = .light
        textSize = .medium
        layoutDensity = .compact
        reducedMotion = true
        highContrast = false
        compactMode = true
        showPreviewImages = false
        
        await saveChanges()
    }
    
    func applyDefaultSettings() async {
        theme = .system
        textSize = .medium
        layoutDensity = .comfortable
        reducedMotion = false
        highContrast = false
        colorBlindnessSupport = .none
        use24HourFormat = false
        showPreviewImages = true
        compactMode = false
        
        await saveChanges()
    }
    
    // MARK: - System integration
    func syncWithSystemSettings() async {
        // Sync with system accessibility settings
        reducedMotion = UIAccessibility.isReduceMotionEnabled
        
        // Sync with system text size if Dynamic Type is enabled
        let systemTextSize = UIApplication.shared.preferredContentSizeCategory
        
        switch systemTextSize {
        case .small, .extraSmall:
            textSize = .small
        case .medium:
            textSize = .medium
        case .large, .extraLarge:
            textSize = .large
        case .extraExtraLarge, .extraExtraExtraLarge:
            textSize = .extraLarge
        default:
            textSize = .medium
        }
        
        await saveChanges()
    }
    
    // MARK: - Computed properties
    var availableLanguageOptions: [(String, String)] {
        availableLanguages
    }
    
    var currentLanguageName: String {
        availableLanguages.first { $0.0 == preferredLanguage }?.1 ?? "English"
    }
    
    var effectiveTheme: AppTheme {
        if let previewTheme = previewTheme {
            return previewTheme
        }
        return theme
    }
    
    var currentColorScheme: ColorScheme? {
        effectiveTheme.colorScheme
    }
    
    var textScaleFactor: CGFloat {
        textSize.scaleFactor
    }
    
    var accessibilityStatus: String {
        var features: [String] = []
        if reducedMotion { features.append("Reduced Motion") }
        if highContrast { features.append("High Contrast") }
        if colorBlindnessSupport != .none { features.append("Color Blindness Support") }
        if textSize != .medium { features.append("Custom Text Size") }
        
        return features.isEmpty ? "Standard" : features.joined(separator: ", ")
    }
    
    var layoutSummary: String {
        var summary = layoutDensity.displayName
        if compactMode { summary += " (Compact)" }
        return summary
    }
    
    var canIncreaseTextSize: Bool {
        textSize != .extraLarge
    }
    
    var canDecreaseTextSize: Bool {
        textSize != .small
    }
}