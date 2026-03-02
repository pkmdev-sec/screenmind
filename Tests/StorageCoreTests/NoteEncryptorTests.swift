import Testing
import Foundation
@testable import StorageCore

@Test func noteEncryptorEncryptsAndDecrypts() throws {
    let plaintext = "Hello, World!"
    let config = NoteEncryptor.Configuration(useMasterPassword: false)

    let encrypted = try NoteEncryptor.encrypt(plaintext, config: config)
    #expect(!encrypted.isEmpty)
    #expect(encrypted != plaintext.data(using: .utf8))

    let decrypted = try NoteEncryptor.decrypt(encrypted, config: config)
    #expect(decrypted == plaintext)
}

@Test func noteEncryptorWithMasterPassword() throws {
    let plaintext = "Secret message"
    let password = "my-secure-password-123"
    let config = NoteEncryptor.Configuration(useMasterPassword: true, password: password)

    let encrypted = try NoteEncryptor.encrypt(plaintext, config: config)
    #expect(!encrypted.isEmpty)

    let decrypted = try NoteEncryptor.decrypt(encrypted, config: config)
    #expect(decrypted == plaintext)
}

@Test func noteEncryptorWrongPasswordFails() throws {
    let plaintext = "Secret message"
    let password = "correct-password"
    let wrongPassword = "wrong-password"

    let config1 = NoteEncryptor.Configuration(useMasterPassword: true, password: password)
    let encrypted = try NoteEncryptor.encrypt(plaintext, config: config1)

    let config2 = NoteEncryptor.Configuration(useMasterPassword: true, password: wrongPassword)

    // Should throw when trying to decrypt with wrong password
    #expect(throws: Error.self) {
        _ = try NoteEncryptor.decrypt(encrypted, config: config2)
    }
}

@Test func noteEncryptorEncryptsEntireNote() throws {
    let title = "Test Title"
    let summary = "Test Summary"
    let details = "Test Details"
    let config = NoteEncryptor.Configuration(useMasterPassword: false)

    let encrypted = try NoteEncryptor.encryptNote(
        title: title,
        summary: summary,
        details: details,
        config: config
    )

    #expect(!encrypted.encryptedTitle.isEmpty)
    #expect(!encrypted.encryptedSummary.isEmpty)
    #expect(!encrypted.encryptedDetails.isEmpty)

    let decrypted = try NoteEncryptor.decryptNote(
        encryptedTitle: encrypted.encryptedTitle,
        encryptedSummary: encrypted.encryptedSummary,
        encryptedDetails: encrypted.encryptedDetails,
        config: config
    )

    #expect(decrypted.title == title)
    #expect(decrypted.summary == summary)
    #expect(decrypted.details == details)
}

@Test func noteEncryptorPasswordHashing() throws {
    let password = "test-password-123"

    let hash1 = try NoteEncryptor.hashPassword(password)
    #expect(!hash1.isEmpty)
    #expect(hash1.count == 64) // SHA-256 hex string is 64 chars

    // Same password should produce same hash (deterministic with salt)
    let hash2 = try NoteEncryptor.hashPassword(password)
    #expect(hash1 == hash2)

    // Verify correct password
    let isValid = try NoteEncryptor.verifyPassword(password, hash: hash1)
    #expect(isValid)

    // Wrong password should fail
    let isInvalid = try NoteEncryptor.verifyPassword("wrong-password", hash: hash1)
    #expect(!isInvalid)
}

@Test func noteEncryptorEmptyPasswordThrows() throws {
    let config = NoteEncryptor.Configuration(useMasterPassword: true, password: "")

    #expect(throws: NoteEncryptionError.self) {
        _ = try NoteEncryptor.encrypt("test", config: config)
    }
}

@Test func noteEncryptorUnicodeSupport() throws {
    let plaintext = "Hello 🌍! Unicode test: 你好 مرحبا"
    let config = NoteEncryptor.Configuration(useMasterPassword: false)

    let encrypted = try NoteEncryptor.encrypt(plaintext, config: config)
    let decrypted = try NoteEncryptor.decrypt(encrypted, config: config)

    #expect(decrypted == plaintext)
}
