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
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            for (collectionName, documents) in json ?? [:] {
                guard let docs = documents as? [String: Any] else { continue }
                print("🗂 Seeding collection: \(collectionName)")

                for (docId, docData) in docs {
                    if let data = docData as? [String: Any] {
                        db.collection(collectionName).document(docId).setData(data) { error in
                            if let error = error {
                                print("❌ Error writing \(docId): \(error)")
                            } else {
                                print("✅ Added document: \(docId)")
                            }
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to load JSON: \(error)")
        }

        // Wait for async Firestore writes to finish before exit
        RunLoop.main.run(until: Date().addingTimeInterval(5))
        print("🎉 Firestore seeding complete.")
    }
}
