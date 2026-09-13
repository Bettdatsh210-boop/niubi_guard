import Foundation

enum AccessEventType: String, Codable, CaseIterable {
    case unlockSuccess = "Unlock succeeded"
    case unlockFailed = "Unlock failed"
    case lock = "Locked"
    case emergencyLock = "Emergency lock"
    case autoLock = "Auto-locked"
    case backgroundLock = "Locked (background)"
}

struct AccessLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let event: AccessEventType
    let detail: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        event: AccessEventType,
        detail: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.event = event
        self.detail = detail
    }
}
