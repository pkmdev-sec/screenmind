import Foundation
import Security

/// Simple Keychain wrapper for storing sensitive values (API keys).
public enum KeychainManager {

    public enum KeychainError: Error, LocalizedError {
        case saveFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case unexpectedData

        public var errorDescription: String? {
            switch self {
            case .saveFailed(let status): "Keychain save failed: \(status)"
            case .retrieveFailed(let status): "Keychain retrieve failed: \(status)"
            case .deleteFailed(let status): "Keychain delete failed: \(status)"
            case .unexpectedData: "Unexpected keychain data format"
            }
        }
    }

    /// Save a string value to the Keychain.
    public static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve a string value from the Keychain with file-based fallback.
    public static func retrieve(key: String) throws -> String? {
        // Try file-based storage first (works with ad-hoc signing)
        if let fileValue = readFromFile(key: key) {
            return fileValue
        }

        // Fall back to Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }

        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }

        return string
    }

    // MARK: - File-based fallback (for ad-hoc signed dev builds)

    private static var configDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/screenmind")
    }

    /// Save API key to a file (chmod 600).
    public static func saveToFile(key: String, value: String) throws {
        let dir = configDir
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent(key)
        try value.write(to: fileURL, atomically: true, encoding: .utf8)
        // Restrict permissions to owner only
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    private static func readFromFile(key: String) -> String? {
        let fileURL = configDir.appendingPathComponent(key)
        return try? String(contentsOf: fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Delete a value from the Keychain.
    public static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
