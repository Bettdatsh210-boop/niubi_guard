import Foundation

enum VaultItemType: String, Codable, CaseIterable {
    case note
    case photo
    case pdf
}

struct VaultItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let type: VaultItemType
    var createdAt: Date
    var updatedAt: Date
    /// Relative filename under the encrypted vault directory (ciphertext only).
    let storageFileName: String
    /// Original filename for imported files (display only).
    var originalFileName: String?
    /// MIME / UTI hint for imported files.
    var contentType: String?

    init(
        id: UUID = UUID(),
        title: String,
        type: VaultItemType,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        storageFileName: String? = nil,
        originalFileName: String? = nil,
        contentType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.storageFileName = storageFileName ?? "\(id.uuidString).vault"
        self.originalFileName = originalFileName
        self.contentType = contentType
    }
}
