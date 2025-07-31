import Foundation
import Combine

// MARK: - Profile settings view model
@MainActor
class ProfileSettingsViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var displayName = ""
    @Published var bio = ""
    @Published var location = ""
    @Published var website = ""
    @Published var phoneNumber = ""
    @Published var skills: [String] = []
    @Published var expertise: [String] = []
    @Published var profileImageURL: String?
    
    // UI state
    @Published var isEditing = false
    @Published var validationErrors: [SettingsValidation.ValidationError] = []
    @Published var showingImagePicker = false
    @Published var newSkill = ""
    @Published var newExpertise = ""
    
    // MARK: - Private properties
    private let settingsService = SettingsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupValidation()
    }
    
    // MARK: - Update settings
    func updateSettings(_ settings: ProfileSettings) {
        displayName = settings.displayName
        bio = settings.bio
        location = settings.location
        website = settings.website
        phoneNumber = settings.phoneNumber
        skills = settings.skills
        expertise = settings.expertise
        profileImageURL = settings.profileImageURL
    }
    
    // MARK: - Create settings object
    func createProfileSettings() -> ProfileSettings {
        var settings = ProfileSettings()
        settings.displayName = displayName
        settings.bio = bio
        settings.location = location
        settings.website = website
        settings.phoneNumber = phoneNumber
        settings.skills = skills
        settings.expertise = expertise
        settings.profileImageURL = profileImageURL
        settings.isProfileComplete = isProfileComplete
        return settings
    }
    
    // MARK: - Validation
    private func setupValidation() {
        // Validate in real-time
        Publishers.CombineLatest4($displayName, $bio, $website, $phoneNumber)
            .map { [weak self] _, _, _, _ in
                guard let self = self else { return [] }
                return SettingsValidation.validateProfileSettings(self.createProfileSettings())
            }
            .assign(to: \.validationErrors, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Save changes
    func saveChanges() async {
        let profileSettings = createProfileSettings()
        
        do {
            try await settingsService.updateProfileSettings(profileSettings)
            isEditing = false
        } catch {
            // Handle error - would be passed up to parent view model
        }
    }
    
    // MARK: - Discard changes
    func discardChanges() {
        if let currentSettings = settingsService.userSettings?.profileSettings {
            updateSettings(currentSettings)
        }
        isEditing = false
    }
    
    // MARK: - Skills management
    func addSkill() {
        guard !newSkill.isEmpty,
              !skills.contains(newSkill),
              skills.count < SettingsConstants.maxSkillsCount else { return }
        
        skills.append(newSkill)
        newSkill = ""
    }
    
    func removeSkill(_ skill: String) {
        skills.removeAll { $0 == skill }
    }
    
    // MARK: - Expertise management
    func addExpertise() {
        guard !newExpertise.isEmpty,
              !expertise.contains(newExpertise),
              expertise.count < SettingsConstants.maxExpertiseCount else { return }
        
        expertise.append(newExpertise)
        newExpertise = ""
    }
    
    func removeExpertise(_ expertiseItem: String) {
        expertise.removeAll { $0 == expertiseItem }
    }
    
    // MARK: - Computed properties
    var isProfileComplete: Bool {
        !displayName.isEmpty && !bio.isEmpty
    }
    
    var hasValidationErrors: Bool {
        !validationErrors.isEmpty
    }
    
    var canSave: Bool {
        !hasValidationErrors && isProfileComplete
    }
    
    var characterCountForBio: String {
        "\(bio.count)/\(SettingsConstants.maxBioLength)"
    }
    
    var characterCountForDisplayName: String {
        "\(displayName.count)/\(SettingsConstants.maxDisplayNameLength)"
    }
    
    var skillsCount: String {
        "\(skills.count)/\(SettingsConstants.maxSkillsCount)"
    }
    
    var expertiseCount: String {
        "\(expertise.count)/\(SettingsConstants.maxExpertiseCount)"
    }
    
    var canAddSkill: Bool {
        !newSkill.isEmpty && skills.count < SettingsConstants.maxSkillsCount && !skills.contains(newSkill)
    }
    
    var canAddExpertise: Bool {
        !newExpertise.isEmpty && expertise.count < SettingsConstants.maxExpertiseCount && !expertise.contains(newExpertise)
    }
}