import Foundation
import FirebaseCore
import FirebaseFirestore

@main
struct FirestoreSeeder {
    static func main() {
        print("🚀 Starting Firestore Seeder...")
        FirebaseApp.configure()
        
        let db = Firestore.firestore()
        let jsonPath = "/Users/rds.development.mqc/Documents/Dev/iSayItForward-iOS/iSayItForward/firestore-seed-v2.json"
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Invalid JSON structure")
                return
            }
            
            for (collectionName, documents) in json {
                guard let docs = documents as? [String: Any] else { continue }
                print("📂 Seeding collection: \(collectionName)")
                
                for (docId, docData) in docs {
                    if let docData = docData as? [String: Any] {
                        db.collection(collectionName).document(docId).setData(docData) { error in
                            if let error = error {
                                print("❌ \(collectionName)/\(docId): \(error.localizedDescription)")
                            } else {
                                print("✅ Wrote \(collectionName)/\(docId)")
                            }
                        }
                    }
                }
            }
            print("🎉 Firestore seeding complete!")
        } catch {
            print("❌ Error reading JSON file: \(error.localizedDescription)")
        }
        
        // Wait a few seconds to let async writes complete before exiting
        RunLoop.main.run(until: Date().addingTimeInterval(5))
    }
}
