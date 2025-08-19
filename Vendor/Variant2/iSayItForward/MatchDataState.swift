import SwiftUI
import Firebase
import FirebaseFirestore

class MatchDataState: ObservableObject {
    @Published var matches: [String: Any] = [:]
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    init() {
        // Initialize without loading data immediately
        print("MatchDataState initialized")
    }
    
    func loadMatches(forUserId userId: String) {
        guard !userId.isEmpty else {
            self.error = "Cannot load matches: No user ID provided"
            return
        }
        
        self.isLoading = true
        
        // Example implementation - adapt to your data structure
        let db = Firestore.firestore()
        db.collection("matches")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = "Failed to load matches: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.error = "No matches found"
                    return
                }
                
                // Process match data
                for document in documents {
                    let data = document.data()
                    self.matches[document.documentID] = data
                }
            }
    }
}
