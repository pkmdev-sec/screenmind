import Foundation
import LocalAuthentication
import CryptoKit
import Shared

/// Manages vault lock state with Touch ID/password authentication and auto-lock.
public actor VaultLockManager {

    public enum LockState: Sendable {
        case locked
        case unlocked
        case disabled // Vault lock not configured
    }

    public enum AuthMethod: String, Sendable, Codable {
        case password
        case touchID
        case both
    }

    private var currentState: LockState = .locked
    private var lastActivityTime: Date = .now
    private var lockTimer: Task<Void, Never>?
    private var failedAttempts: Int = 0
    private var lockoutUntil: Date?

    private static let passwordHashKey = "com.screenmind.vault-password-hash"
    private static let maxFailedAttempts = 5
    private static let baseLockoutDuration: TimeInterval = 60 // 1 minute

    public init() {
        // Check if vault is configured
        let isConfigured = UserDefaults.standard.bool(forKey: "vaultLockEnabled")
        if isConfigured {
            currentState = .locked
        } else {
            currentState = .disabled
        }
    }

    // MARK: - Public API

    /// Current lock state.
    public var state: LockState {
        currentState
    }

    /// Whether vault lock is configured.
    public func isVaultConfigured() -> Bool {
        UserDefaults.standard.bool(forKey: "vaultLockEnabled")
    }

    /// Auto-lock timeout in seconds (default: 900 = 15 minutes).
    public var autoLockTimeout: TimeInterval {
        TimeInterval(UserDefaults.standard.integer(forKey: "vaultLockTimeout").orDefault(900))
    }

    /// Unlock vault with password.
    public func unlock(password: String) async throws {
        try checkLockout()

        guard let storedHash = try? KeychainManager.retrieve(key: Self.passwordHashKey) else {
            throw VaultError.notConfigured
        }

        // Import NoteEncryptor for password verification
        guard try await verifyPasswordHash(password, storedHash: storedHash) else {
            failedAttempts += 1
            if failedAttempts >= Self.maxFailedAttempts {
                applyExponentialLockout()
            }
            throw VaultError.invalidPassword
        }

        failedAttempts = 0
        lockoutUntil = nil
        currentState = .unlocked
        lastActivityTime = .now
        startAutoLockTimer()
        SMLogger.system.info("Vault unlocked")
    }

    /// Unlock vault with Touch ID / Face ID.
    public func unlockWithBiometrics() async throws {
        try checkLockout()

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw VaultError.biometricsNotAvailable
        }

        let reason = "Unlock ScreenMind vault"
        let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

        if success {
            failedAttempts = 0
            lockoutUntil = nil
            currentState = .unlocked
            lastActivityTime = .now
            startAutoLockTimer()
            SMLogger.system.info("Vault unlocked with biometrics")
        } else {
            failedAttempts += 1
            if failedAttempts >= Self.maxFailedAttempts {
                applyExponentialLockout()
            }
            throw VaultError.biometricsFailed
        }
    }

    /// Lock vault immediately.
    public func lock() {
        currentState = .locked
        lockTimer?.cancel()
        lockTimer = nil
        SMLogger.system.info("Vault locked")
    }

    /// Configure vault with password.
    public func configure(password: String) async throws {
        guard !password.isEmpty else {
            throw VaultError.weakPassword("Password cannot be empty")
        }

        guard password.count >= 8 else {
            throw VaultError.weakPassword("Password must be at least 8 characters")
        }

        // Hash password
        let hash = try await hashPassword(password)

        // Save to Keychain
        try KeychainManager.save(key: Self.passwordHashKey, value: hash)

        // Enable vault
        UserDefaults.standard.set(true, forKey: "vaultLockEnabled")

        currentState = .unlocked
        lastActivityTime = .now
        startAutoLockTimer()
        SMLogger.system.info("Vault configured")
    }

    /// Disable vault lock.
    public func disable(password: String) async throws {
        try await unlock(password: password)
        UserDefaults.standard.set(false, forKey: "vaultLockEnabled")
        try? KeychainManager.delete(key: Self.passwordHashKey)
        currentState = .disabled
        lockTimer?.cancel()
        lockTimer = nil
        SMLogger.system.info("Vault disabled")
    }

    /// Check if Touch ID / Face ID is available.
    public func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Reset failed attempts (admin override).
    public func resetFailedAttempts() {
        failedAttempts = 0
        lockoutUntil = nil
    }

    /// Get remaining lockout time in seconds (0 if not locked out).
    public func getRemainingLockoutTime() -> TimeInterval {
        guard let lockoutUntil else { return 0 }
        let remaining = lockoutUntil.timeIntervalSinceNow
        return max(0, remaining)
    }

    // MARK: - Auto-Lock

    /// Record user activity to reset auto-lock timer.
    public func recordActivity() {
        guard currentState == .unlocked else { return }
        lastActivityTime = .now
    }

    private func startAutoLockTimer() {
        lockTimer?.cancel()

        lockTimer = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))

                let state = await self.currentState
                let lastActivity = await self.lastActivityTime
                let timeout = await self.autoLockTimeout

                if state == .unlocked {
                    let elapsed = Date.now.timeIntervalSince(lastActivity)
                    if elapsed >= timeout {
                        await self.lock()
                        break
                    }
                }
            }
        }
    }

    // MARK: - Lockout Management

    private func checkLockout() throws {
        guard let lockoutUntil else { return }

        if Date.now < lockoutUntil {
            let remaining = Int(lockoutUntil.timeIntervalSinceNow)
            throw VaultError.lockedOut(seconds: remaining)
        } else {
            self.lockoutUntil = nil
            failedAttempts = 0
        }
    }

    private func applyExponentialLockout() {
        let multiplier = pow(2.0, Double(self.failedAttempts - Self.maxFailedAttempts))
        let duration = Self.baseLockoutDuration * multiplier
        lockoutUntil = Date.now.addingTimeInterval(duration)
        SMLogger.system.warning("Vault locked out for \(Int(duration))s after \(self.failedAttempts) failed attempts")
    }

    // MARK: - Password Hashing

    private func hashPassword(_ password: String) async throws -> String {
        return try await Task.detached {
            let data = Data(password.utf8)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        }.value
    }

    private func verifyPasswordHash(_ password: String, storedHash: String) async throws -> Bool {
        let computed = try await hashPassword(password)
        return computed == storedHash
    }
}

// MARK: - Errors

public enum VaultError: Error, LocalizedError {
    case notConfigured
    case invalidPassword
    case biometricsNotAvailable
    case biometricsFailed
    case weakPassword(String)
    case lockedOut(seconds: Int)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Vault is not configured"
        case .invalidPassword:
            return "Invalid password"
        case .biometricsNotAvailable:
            return "Touch ID / Face ID is not available"
        case .biometricsFailed:
            return "Biometric authentication failed"
        case .weakPassword(let reason):
            return "Weak password: \(reason)"
        case .lockedOut(let seconds):
            return "Too many failed attempts. Try again in \(seconds) seconds"
        }
    }
}

// MARK: - Helper Extensions

extension Int {
    func orDefault(_ defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
