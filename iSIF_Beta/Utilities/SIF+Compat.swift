import Foundation

extension SIF {
    /// UI helper used by Inbox filters/counters.
    var isScheduled: Bool { deliveryDate != nil }
}
