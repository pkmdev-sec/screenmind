import Foundation
import CryptoKit
import Shared

/// Encrypts and decrypts note fields (title, summary, details) using AES-GCM-256.
/// Supports master password with PBKDF2 key derivation for zero-knowledge encryption.
public struct NoteEncryptor: Sendable {

    private static let keychainKey = "com.screenmind.note-encryption-key"
    private static let saltKey = "com.screenmind.note-encryption-salt"
    private static let pbkdf2Iterations = 600_000

    /// Whether note encryption is enabled.
    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "noteEncryptionEnabled")
    }

    /// Configuration for encryption with optional master password.
    public struct Configuration: Sendable {
        public let useMasterPassword: Bool
        public let password: String?

        public init(useMasterPassword: Bool = false, password: String? = nil) {
            self.useMasterPassword = useMasterPassword
            self.password = password
        }
    }

    // MARK: - Public API

    /// Encrypt a note field (title, summary, or details).
    public static func encrypt(_ plaintext: String, config: Configuration = Configuration()) throws -> Data {
        let key = try getKey(config: config)
        let data = plaintext.data(using: .utf8) ?? Data()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.sealFailed
        }
        return combined
    }

    /// Decrypt a note field.
    public static func decrypt(_ ciphertext: Data, config: Configuration = Configuration()) throws -> String {
        let key = try getKey(config: config)
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        let data = try AES.GCM.open(sealedBox, using: key)
        guard let plaintext = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return plaintext
    }

    /// Encrypt note fields and return encrypted blobs.
    public struct EncryptedNote: Sendable {
        public let encryptedTitle: Data
        public let encryptedSummary: Data
        public let encryptedDetails: Data

        public init(encryptedTitle: Data, encryptedSummary: Data, encryptedDetails: Data) {
            self.encryptedTitle = encryptedTitle
            self.encryptedSummary = encryptedSummary
            self.encryptedDetails = encryptedDetails
        }
    }

    /// Encrypt all note fields at once.
    public static func encryptNote(
        title: String,
        summary: String,
        details: String,
        config: Configuration = Configuration()
    ) throws -> EncryptedNote {
        let encryptedTitle = try encrypt(title, config: config)
        let encryptedSummary = try encrypt(summary, config: config)
        let encryptedDetails = try encrypt(details, config: config)

        return EncryptedNote(
            encryptedTitle: encryptedTitle,
            encryptedSummary: encryptedSummary,
            encryptedDetails: encryptedDetails
        )
    }

    /// Decrypt all note fields at once.
    public static func decryptNote(
        encryptedTitle: Data,
        encryptedSummary: Data,
        encryptedDetails: Data,
        config: Configuration = Configuration()
    ) throws -> (title: String, summary: String, details: String) {
        let title = try decrypt(encryptedTitle, config: config)
        let summary = try decrypt(encryptedSummary, config: config)
        let details = try decrypt(encryptedDetails, config: config)

        return (title, summary, details)
    }

    // MARK: - Key Management

    /// Get or create encryption key based on configuration.
    private static func getKey(config: Configuration) throws -> SymmetricKey {
        if config.useMasterPassword {
            guard let password = config.password, !password.isEmpty else {
                throw NoteEncryptionError.passwordRequired
            }
            return try deriveKeyFromPassword(password: password)
        } else {
            return try getOrCreateDataEncryptionKey()
        }
    }

    /// Get or create the data encryption key (DEK) stored in Keychain.
    private static func getOrCreateDataEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key
        if let existingKeyString = try? KeychainManager.retrieve(key: keychainKey),
           let keyData = Data(base64Encoded: existingKeyString) {
            return SymmetricKey(data: keyData)
        }

        // Generate new 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        let keyString = keyData.base64EncodedString()

        // Try to save to Keychain (may fail in test environment)
        do {
            try KeychainManager.save(key: keychainKey, value: keyString)
            SMLogger.storage.info("New note encryption key generated and stored in Keychain")
        } catch {
            // In test environment, keychain may not be available - just use the generated key
            SMLogger.storage.warning("Failed to save encryption key to Keychain (test environment?): \(error)")
        }
        return newKey
    }

    /// Derive encryption key from user password using PBKDF2.
    private static func deriveKeyFromPassword(password: String) throws -> SymmetricKey {
        let salt = try getOrCreateSalt()
        let passwordData = password.data(using: .utf8) ?? Data()

        // Use PBKDF2 with HMAC-SHA256
        var derivedKeyData = Data(count: 32) // 256 bits
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(pbkdf2Iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            throw NoteEncryptionError.keyDerivationFailed
        }

        return SymmetricKey(data: derivedKeyData)
    }

    /// Get or create salt for PBKDF2.
    private static func getOrCreateSalt() throws -> Data {
        // Try to load existing salt
        if let existingSaltString = try? KeychainManager.retrieve(key: saltKey),
           let salt = Data(base64Encoded: existingSaltString) {
            return salt
        }

        // Generate new 32-byte salt
        var salt = Data(count: 32)
        let result = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }

        guard result == errSecSuccess else {
            throw NoteEncryptionError.saltGenerationFailed
        }

        let saltString = salt.base64EncodedString()
        // Try to save to Keychain (may fail in test environment)
        do {
            try KeychainManager.save(key: saltKey, value: saltString)
            SMLogger.storage.info("New encryption salt generated and stored in Keychain")
        } catch {
            // In test environment, keychain may not be available - just use the generated salt
            SMLogger.storage.warning("Failed to save encryption salt to Keychain (test environment?): \(error)")
        }
        return salt
    }

    // MARK: - Password Hashing (for vault lock)

    /// Hash password for storage (used by VaultLockManager).
    /// Uses SHA-256 with salt for password verification.
    public static func hashPassword(_ password: String) throws -> String {
        let salt = try getOrCreateSalt()
        let passwordData = password.data(using: .utf8) ?? Data()

        var combined = salt
        combined.append(passwordData)

        let hash = SHA256.hash(data: combined)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Verify password against stored hash.
    public static func verifyPassword(_ password: String, hash: String) throws -> Bool {
        let computedHash = try hashPassword(password)
        return computedHash == hash
    }
}

// MARK: - CommonCrypto Import

import CommonCrypto

/// Additional encryption errors for note encryption.
public enum NoteEncryptionError: Error, LocalizedError {
    case passwordRequired
    case keyDerivationFailed
    case saltGenerationFailed

    public var errorDescription: String? {
        switch self {
        case .passwordRequired:
            return "Master password is required but not provided"
        case .keyDerivationFailed:
            return "Failed to derive key from password"
        case .saltGenerationFailed:
            return "Failed to generate random salt"
        }
    }
}
