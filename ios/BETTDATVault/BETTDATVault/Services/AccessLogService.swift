import Foundation

@MainActor
final class AccessLogService: ObservableObject {
    static let shared = AccessLogService()

    @Published private(set) var entries: [AccessLogEntry] = []
    /// Safe to show on the lock screen (not the full log).
    @Published private(set) var lastFailedAttemptDate: Date?

    private let fileName = "access_log.vault"
    private let lastFailedFileName = "last_failed_attempt.json"
    private let maxEntries = 500

    private var directoryURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vaultDir = dir.appendingPathComponent("BETTDATVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        return vaultDir
    }

    private var fileURL: URL { directoryURL.appendingPathComponent(fileName) }
    private var lastFailedURL: URL { directoryURL.appendingPathComponent(lastFailedFileName) }

    private init() {
        loadLastFailedSidecar()
        // Full encrypted log is loaded after EncryptionService is prepared (see reloadEncryptedLog).
    }

    /// Call after EncryptionService.prepare().
    func reloadEncryptedLog() {
        loadEncrypted()
    }

    func append(_ event: AccessEventType, detail: String? = nil) {
        let entry = AccessLogEntry(event: event, detail: detail)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        if event == .unlockFailed {
            lastFailedAttemptDate = entry.timestamp
            persistLastFailedSidecar()
        }
        persistEncrypted()
    }

    func wipe() {
        entries = []
        lastFailedAttemptDate = nil
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: lastFailedURL)
    }

    var lastFailedAttempt: AccessLogEntry? {
        if let date = lastFailedAttemptDate {
            return AccessLogEntry(timestamp: date, event: .unlockFailed)
        }
        return entries.first { $0.event == .unlockFailed }
    }

    private func loadLastFailedSidecar() {
        guard let data = try? Data(contentsOf: lastFailedURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ts = obj["timestamp"] as? TimeInterval else {
            lastFailedAttemptDate = nil
            return
        }
        lastFailedAttemptDate = Date(timeIntervalSince1970: ts)
    }

    private func persistLastFailedSidecar() {
        guard let date = lastFailedAttemptDate else {
            try? FileManager.default.removeItem(at: lastFailedURL)
            return
        }
        let obj: [String: Any] = ["timestamp": date.timeIntervalSince1970]
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]) {
            try? data.write(to: lastFailedURL, options: [.atomic])
        }
    }

    private func loadEncrypted() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let combined = try? Data(contentsOf: fileURL),
              let plain = try? EncryptionService.shared.decrypt(combined) else {
            // Keep any in-memory entries; first launch may have empty log.
            if entries.isEmpty { entries = [] }
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        entries = (try? decoder.decode([AccessLogEntry].self, from: plain)) ?? []
    }

    private func persistEncrypted() {
        // Best-effort: if crypto isn't ready yet, skip disk write until prepare().
        guard let _ = try? EncryptionService.shared.prepare() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let plain = try? encoder.encode(entries),
              let combined = try? EncryptionService.shared.encrypt(plain) else { return }
        try? combined.write(to: fileURL, options: [.atomic])
    }
}
