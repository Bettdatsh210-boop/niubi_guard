import Foundation
import CryptoKit

enum EncryptionError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidCombinedData

    var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Encryption failed."
        case .decryptionFailed: return "Decryption failed."
        case .invalidCombinedData: return "Invalid ciphertext format."
        }
    }
}

/// AES-GCM encryption using a Keychain-backed 256-bit key (CryptoKit).
final class EncryptionService {
    static let shared = EncryptionService()

    private var key: SymmetricKey?

    private init() {}

    func prepare() throws {
        let keyData = try KeychainService.shared.loadOrCreateSymmetricKeyData(byteCount: 32)
        key = SymmetricKey(data: keyData)
    }

    private func requireKey() throws -> SymmetricKey {
        if let key { return key }
        try prepare()
        guard let key else { throw EncryptionError.encryptionFailed }
        return key
    }

    /// Returns nonce (12) + ciphertext+tag combined Data.
    func encrypt(_ plaintext: Data) throws -> Data {
        let key = try requireKey()
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key)
            guard let combined = sealed.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(_ combined: Data) throws -> Data {
        let key = try requireKey()
        do {
            let box = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }

    func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed
        }
        return try encrypt(data)
    }

    func decryptString(_ combined: Data) throws -> String {
        let data = try decrypt(combined)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return string
    }
}
