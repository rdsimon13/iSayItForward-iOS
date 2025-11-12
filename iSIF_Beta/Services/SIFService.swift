import Foundation

public protocol SIFProviding {
    @discardableResult func saveSIF(_ sif: SIF) async throws -> String
    func fetchSentSIFs(for uid: String) async throws -> [SIF]
}

public final class SIFService: SIFProviding {
    public static let shared = SIFService()
    private init() {}
    private var sentSIFs: [SIF] = []

    public func saveSIF(_ sif: SIF) async throws -> String {
        var newSIF = sif
        newSIF.id = UUID().uuidString
        newSIF.createdAt = Date()
        newSIF.status = "sent"
        sentSIFs.insert(newSIF, at: 0)
        return newSIF.id
    }

    public func fetchSentSIFs(for uid: String) async throws -> [SIF] {
        return sentSIFs.filter { $0.senderUID == uid }
    }
}
