import Foundation

/// Shim so legacy `SIFDataManager.shared` references keep compiling.
/// ObservableObject so views can use @StateObject/@ObservedObject.
public final class SIFDataManager: ObservableObject {
    public static let shared = SIFDataManager()

    private let service: SIFProviding
    @Published public private(set) var sent: [SIF] = []

    public init(service: SIFProviding = SIFService.shared) {
        self.service = service
    }

    @discardableResult
    public func send(_ sif: SIF) async throws -> String {
        try await service.saveSIF(sif)
    }

    @MainActor
    public func loadSent(for uid: String) async {
        do {
            self.sent = try await service.fetchSentSIFs(for: uid)
        } catch {
            self.sent = []
        }
    }

    public func fetchSent(for uid: String) async throws -> [SIF] {
        try await service.fetchSentSIFs(for: uid)
    }
}
