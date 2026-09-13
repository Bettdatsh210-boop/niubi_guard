import Foundation

enum VaultStoreError: Error, LocalizedError {
    case notReady
    case itemNotFound
    case writeFailed
    case readFailed

    var errorDescription: String? {
        switch self {
        case .notReady: return "Vault is not ready."
        case .itemNotFound: return "Item not found."
        case .writeFailed: return "Could not write encrypted data."
        case .readFailed: return "Could not read encrypted data."
        }
    }
}

@MainActor
final class VaultStore: ObservableObject {
    static let shared = VaultStore()

    @Published private(set) var items: [VaultItem] = []
    @Published private(set) var isReady = false

    private let indexFileName = "vault_index.vault"

    private var rootURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("BETTDATVault/encrypted", isDirectory: true)
    }

    private var indexURL: URL {
        rootURL.appendingPathComponent(indexFileName)
    }

    private init() {}

    func prepare() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try EncryptionService.shared.prepare()
        try loadIndex()
        isReady = true
    }

    // MARK: - Notes

    func addNote(title: String, body: String) throws -> VaultItem {
        try ensureReady()
        let item = VaultItem(title: title.isEmpty ? "Untitled Note" : title, type: .note)
        let ciphertext = try EncryptionService.shared.encryptString(body)
        try writeCiphertext(ciphertext, for: item)
        items.insert(item, at: 0)
        try persistIndex()
        return item
    }

    func updateNote(_ item: VaultItem, title: String, body: String) throws {
        try ensureReady()
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
            throw VaultStoreError.itemNotFound
        }
        var updated = items[idx]
        updated.title = title.isEmpty ? "Untitled Note" : title
        updated.updatedAt = Date()
        let ciphertext = try EncryptionService.shared.encryptString(body)
        try writeCiphertext(ciphertext, for: updated)
        items[idx] = updated
        try persistIndex()
    }

    func loadNoteBody(_ item: VaultItem) throws -> String {
        try ensureReady()
        let data = try readCiphertext(for: item)
        return try EncryptionService.shared.decryptString(data)
    }

    // MARK: - Files (photos / PDFs)

    func importFile(
        title: String,
        data: Data,
        type: VaultItemType,
        originalFileName: String?,
        contentType: String?
    ) throws -> VaultItem {
        try ensureReady()
        let item = VaultItem(
            title: title.isEmpty ? (originalFileName ?? "Imported File") : title,
            type: type,
            originalFileName: originalFileName,
            contentType: contentType
        )
        let ciphertext = try EncryptionService.shared.encrypt(data)
        try writeCiphertext(ciphertext, for: item)
        items.insert(item, at: 0)
        try persistIndex()
        return item
    }

    func loadFileData(_ item: VaultItem) throws -> Data {
        try ensureReady()
        let ciphertext = try readCiphertext(for: item)
        return try EncryptionService.shared.decrypt(ciphertext)
    }

    // MARK: - Shared

    func delete(_ item: VaultItem) throws {
        try ensureReady()
        let url = rootURL.appendingPathComponent(item.storageFileName)
        try? FileManager.default.removeItem(at: url)
        items.removeAll { $0.id == item.id }
        try persistIndex()
    }

    func clearAllDecryptedCaches() {
        // Content is loaded on demand; dismiss detail views on lock.
    }

    // MARK: - Private

    private func ensureReady() throws {
        if !isReady {
            try prepare()
        }
    }

    private func writeCiphertext(_ data: Data, for item: VaultItem) throws {
        let url = rootURL.appendingPathComponent(item.storageFileName)
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw VaultStoreError.writeFailed
        }
    }

    private func readCiphertext(for item: VaultItem) throws -> Data {
        let url = rootURL.appendingPathComponent(item.storageFileName)
        guard let data = try? Data(contentsOf: url) else {
            throw VaultStoreError.readFailed
        }
        return data
    }

    private func loadIndex() throws {
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            items = []
            return
        }
        guard let combined = try? Data(contentsOf: indexURL) else {
            items = []
            return
        }
        let plain = try EncryptionService.shared.decrypt(combined)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([VaultItem].self, from: plain)) ?? []
    }

    private func persistIndex() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let plain = try? encoder.encode(items) else {
            throw VaultStoreError.writeFailed
        }
        let combined = try EncryptionService.shared.encrypt(plain)
        try combined.write(to: indexURL, options: [.atomic])
    }
}
