import Foundation
import CryptoKit
import Shared

/// Encrypts and decrypts screenshot files using AES-GCM-256.
/// Encryption key is derived from a master key stored in the macOS Keychain.
public struct ScreenshotEncryptor: Sendable {

    private static let keychainKey = "com.screenmind.encryption-key"

    /// Whether screenshot encryption is enabled.
    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "privacyScreenshotEncryption")
    }

    /// Encrypt data using AES-GCM-256. Returns sealed box data (nonce + ciphertext + tag).
    /// Security: CryptoKit generates cryptographically random nonces via SecRandomCopyBytes,
    /// ensuring nonce uniqueness without manual nonce management.
    public static func encrypt(_ plaintext: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.sealFailed
        }
        return combined
    }

    /// Decrypt AES-GCM sealed box data.
    public static func decrypt(_ ciphertext: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Encrypt a file on disk in-place. Appends .enc extension.
    /// Removes the plaintext original atomically — if encrypted write fails, original is preserved.
    public static func encryptFile(at path: String) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let encrypted = try encrypt(data)
        let encPath = path + ".enc"
        try encrypted.write(to: URL(fileURLWithPath: encPath), options: .atomic)
        // Remove the unencrypted original only after encrypted file is confirmed on disk
        try FileManager.default.removeItem(atPath: path)
        SMLogger.storage.info("Screenshot encrypted: \(encPath)")
        return encPath
    }

    /// Encrypt raw data and write directly to an encrypted file path.
    /// Avoids writing plaintext to disk entirely.
    public static func encryptAndSave(_ data: Data, to path: String) throws -> String {
        let encrypted = try encrypt(data)
        let encPath = path + ".enc"
        try encrypted.write(to: URL(fileURLWithPath: encPath), options: .atomic)
        SMLogger.storage.info("Screenshot encrypted directly: \(encPath)")
        return encPath
    }

    /// Decrypt a .enc file and return the raw image data (does not write to disk).
    public static func decryptFile(at path: String) throws -> Data {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decrypt(data)
    }

    // MARK: - Key Management

    /// Get or create the 256-bit symmetric encryption key from Keychain.
    private static func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key
        if let existingKeyString = try? KeychainManager.retrieve(key: keychainKey),
           let keyData = Data(base64Encoded: existingKeyString) {
            return SymmetricKey(data: keyData)
        }

        // Generate new 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        let keyString = keyData.base64EncodedString()

        try KeychainManager.save(key: keychainKey, value: keyString)
        SMLogger.storage.info("New encryption key generated and stored in Keychain")
        return newKey
    }
}

/// Encryption errors.
public enum EncryptionError: Error, LocalizedError {
    case sealFailed
    case keyGenerationFailed
    case decryptionFailed

    public var errorDescription: String? {
        switch self {
        case .sealFailed: return "Failed to encrypt data"
        case .keyGenerationFailed: return "Failed to generate encryption key"
        case .decryptionFailed: return "Failed to decrypt data — wrong key or corrupted data"
        }
    }
}
