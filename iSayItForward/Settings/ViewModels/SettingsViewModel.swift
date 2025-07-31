import Foundation
import Combine
import FirebaseAuth

// MARK: - Main settings view model
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var userSettings: UserSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var lastSyncDate: Date?
    
    // MARK: - Child view models
    @Published var profileViewModel: ProfileSettingsViewModel
    @Published var privacyViewModel: PrivacySettingsViewModel
    @Published var notificationViewModel: NotificationSettingsViewModel
    @Published var appearanceViewModel: AppearanceSettingsViewModel
    
    // MARK: - Services
    private let settingsService = SettingsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.profileViewModel = ProfileSettingsViewModel()
        self.privacyViewModel = PrivacySettingsViewModel()
        self.notificationViewModel = NotificationSettingsViewModel()
        self.appearanceViewModel = AppearanceSettingsViewModel()
        
        setupBindings()
        loadSettings()
    }
    
    // MARK: - Setup bindings
    private func setupBindings() {
        // Bind settings service to local state
        settingsService.$userSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.userSettings = settings
                self?.updateChildViewModels(with: settings)
            }
            .store(in: &cancellables)
        
        settingsService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        settingsService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showingError = true
                }
            }
            .store(in: &cancellables)
        
        settingsService.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastSyncDate, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Update child view models
    private func updateChildViewModels(with settings: UserSettings?) {
        guard let settings = settings else { return }
        
        profileViewModel.updateSettings(settings.profileSettings)
        privacyViewModel.updateSettings(settings.privacySettings)
        notificationViewModel.updateSettings(settings.notificationSettings)
        appearanceViewModel.updateSettings(settings.appearanceSettings)
    }
    
    // MARK: - Load settings
    func loadSettings() {
        Task {
            do {
                try await settingsService.loadSettings()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Refresh settings
    func refreshSettings() {
        settingsService.clearCache()
        loadSettings()
    }
    
    // MARK: - Save settings
    func saveSettings() async {
        guard let settings = userSettings else { return }
        
        do {
            try await settingsService.saveSettings(settings)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    // MARK: - Reset to defaults
    func resetToDefaults() async {
        do {
            try await settingsService.resetToDefaults()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    // MARK: - Settings sections status
    var profileCompletionPercentage: Double {
        guard let profile = userSettings?.profileSettings else { return 0 }
        
        var completedFields = 0
        let totalFields = 6 // displayName, bio, location, website, phoneNumber, skills
        
        if !profile.displayName.isEmpty { completedFields += 1 }
        if !profile.bio.isEmpty { completedFields += 1 }
        if !profile.location.isEmpty { completedFields += 1 }
        if !profile.website.isEmpty { completedFields += 1 }
        if !profile.phoneNumber.isEmpty { completedFields += 1 }
        if !profile.skills.isEmpty { completedFields += 1 }
        
        return Double(completedFields) / Double(totalFields)
    }
    
    var hasNotificationPermissions: Bool {
        // This would integrate with the system notification permissions
        // For now, return true as a placeholder
        return true
    }
    
    var isDataSyncEnabled: Bool {
        userSettings?.privacySettings.allowDataCollection ?? false
    }
    
    // MARK: - Quick actions
    func toggleNotifications() async {
        guard var settings = userSettings else { return }
        settings.notificationSettings.pushNotificationsEnabled.toggle()
        
        do {
            try await settingsService.updateNotificationSettings(settings.notificationSettings)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func toggleDarkMode() async {
        guard var settings = userSettings else { return }
        
        switch settings.appearanceSettings.theme {
        case .light:
            settings.appearanceSettings.theme = .dark
        case .dark:
            settings.appearanceSettings.theme = .light
        case .system:
            settings.appearanceSettings.theme = .dark
        }
        
        do {
            try await settingsService.updateAppearanceSettings(settings.appearanceSettings)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func togglePrivateProfile() async {
        guard var settings = userSettings else { return }
        
        let newVisibility: ProfileVisibility = settings.privacySettings.profileVisibility == .publicProfile
            ? .privateProfile
            : .publicProfile
        
        settings.privacySettings.profileVisibility = newVisibility
        
        do {
            try await settingsService.updatePrivacySettings(settings.privacySettings)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    // MARK: - Dismiss error
    func dismissError() {
        showingError = false
        errorMessage = nil
    }
    
    // MARK: - Computed properties for UI
    var formattedLastSync: String {
        guard let lastSyncDate = lastSyncDate else { return "Never" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastSyncDate)
    }
    
    var currentUser: User? {
        Auth.auth().currentUser
    }
    
    var isSignedIn: Bool {
        currentUser != nil
    }
}