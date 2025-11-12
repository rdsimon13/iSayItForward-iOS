import Foundation

/// Minimal shim to satisfy legacy references like `SIFDataManager.shared`.
/// Internally delegates to the protocol-backed SIFService.
public final class SIFDataManager {
    public static let shared = SIFDataManager()
    private let service: SIFProviding

    public init(service: SIFProviding = SIFService.shared) {
        self.service = service
    }

    // Legacy-style helpers; extend as needed by older views.
    @discardableResult
    public func send(_ sif: SIF) async throws -> String {
        try await service.saveSIF(sif)
    }

    public func fetchSent(for uid: String) async throws -> [SIF] {
        try await service.fetchSentSIFs(for: uid)
    }
}
