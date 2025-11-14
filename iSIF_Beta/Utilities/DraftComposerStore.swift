import Foundation

protocol DraftComposerStoring {
    func saveDraft(_ draft: String, forKey key: String)
    func loadDraft(forKey key: String) -> String?
    func deleteDraft(forKey key: String)
}

class DraftComposerStore: DraftComposerStoring {
    private let userDefaults = UserDefaults.standard

    func saveDraft(_ draft: String, forKey key: String) {
        if let data = draft.data(using: .utf8) {
            userDefaults.set(data, forKey: key)
        }
    }

    func loadDraft(forKey key: String) -> String? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteDraft(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}