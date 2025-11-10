import Foundation
import FirebaseCore
import FirebaseFirestore

// MARK: - Firestore Seeder
struct FirestoreSeeder {
    static func main() {
        print("🚀 Starting Firestore Seeder...")
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ Found GoogleService-Info.plist at \(path)")
        } else {
            print("❌ Still missing GoogleService-Info.plist")
        }
        
        // Configure Firebase
        FirebaseApp.configure()

        let db = Firestore.firestore()
        let jsonPath = "/Users/rds.development.mqc/Documents/Dev/iSIF_Beta/iSIF_Beta/FirestoreSeeder/firestore-seed-v2.json"

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Invalid JSON structure.")
                return
            }

            for (collectionName, documents) in json {
                guard let docs = documents as? [String: Any] else { continue }
                print("📁 Seeding collection: \(collectionName)")

                for (docId, docData) in docs {
                    guard let docData = docData as? [String: Any] else { continue }

                    db.collection(collectionName).document(docId).setData(docData) { error in
                        if let error = error {
                            print("❌ Error writing \(collectionName)/\(docId): \(error.localizedDescription)")
                        } else {
                            print("✅ Wrote \(collectionName)/\(docId)")
                        }
                    }
                }
            }

            // Give async Firestore writes time to complete
            RunLoop.main.run(until: Date().addingTimeInterval(5))
            print("🎉 Firestore seeding complete!")

        } catch {
            print("💥 Failed to load or parse JSON: \(error.localizedDescription)")
        }
    }
}

// MARK: - Run Seeder
FirestoreSeeder.main()
