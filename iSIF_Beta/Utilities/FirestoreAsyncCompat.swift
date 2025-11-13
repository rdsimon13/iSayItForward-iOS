import FirebaseFirestore

public extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { cont in
            self.getDocuments { snap, err in
                if let err = err { 
                    cont.resume(throwing: err) 
                } else if let snap = snap { 
                    cont.resume(returning: snap) 
                } else { 
                    cont.resume(throwing: NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }
    }
}

public extension DocumentReference {
    func setDataAsync(_ data: [String: Any], merge: Bool = false) async throws {
        try await withCheckedThrowingContinuation { cont in
            self.setData(data, merge: merge) { err in
                if let err = err { 
                    cont.resume(throwing: err) 
                } else { 
                    cont.resume(returning: ()) 
                }
            }
        }
    }
}
