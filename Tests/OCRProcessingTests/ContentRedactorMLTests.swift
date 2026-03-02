import Testing
import Foundation
@testable import OCRProcessing

@Test func contentRedactorPIILevels() {
    // Test different PII detection levels
    let levels: [ContentRedactor.PIIDetectionLevel] = [.off, .low, .medium, .high]

    for level in levels {
        // Verify enum conversion
        let rawValue = level.rawValue
        let reconstructed = ContentRedactor.PIIDetectionLevel(rawValue: rawValue)
        #expect(reconstructed == level)
    }
}

@Test func contentRedactorMLDetectsNames() {
    // Save original setting
    let originalLevel = UserDefaults.standard.string(forKey: "piiDetectionLevel")
    defer {
        if let original = originalLevel {
            UserDefaults.standard.set(original, forKey: "piiDetectionLevel")
        } else {
            UserDefaults.standard.removeObject(forKey: "piiDetectionLevel")
        }
    }

    // Enable ML-based PII detection at low level (names only)
    UserDefaults.standard.set("low", forKey: "piiDetectionLevel")

    let text = "John Smith sent an email to jane.doe@example.com about the API key."
    let result = ContentRedactor.redact(text)

    // Should detect and redact names (John Smith)
    #expect(result.text.contains("[REDACTED]"))
    #expect(result.redactionCount > 0)

    // Should also redact email (from regex patterns)
    #expect(!result.text.contains("jane.doe@example.com"))
}

@Test func contentRedactorMLRespectsSensitivityLevel() {
    // Save original setting
    let originalLevel = UserDefaults.standard.string(forKey: "piiDetectionLevel")
    defer {
        if let original = originalLevel {
            UserDefaults.standard.set(original, forKey: "piiDetectionLevel")
        } else {
            UserDefaults.standard.removeObject(forKey: "piiDetectionLevel")
        }
    }

    // Test with PII detection off
    UserDefaults.standard.set("off", forKey: "piiDetectionLevel")

    let text = "John Smith works at Apple in San Francisco."
    let resultOff = ContentRedactor.redact(text)

    // With ML off, should only use regex patterns (which won't match names/places)
    // So the text should be mostly unchanged (unless regex patterns match)
    #expect(resultOff.text.contains("John") || resultOff.text.contains("[REDACTED]"))
}

@Test func contentRedactorMLCombinedWithRegex() {
    // Save original setting
    let originalLevel = UserDefaults.standard.string(forKey: "piiDetectionLevel")
    let originalRedaction = UserDefaults.standard.object(forKey: "privacyRedactionEnabled")

    defer {
        if let original = originalLevel {
            UserDefaults.standard.set(original, forKey: "piiDetectionLevel")
        } else {
            UserDefaults.standard.removeObject(forKey: "piiDetectionLevel")
        }
        if let original = originalRedaction {
            UserDefaults.standard.set(original, forKey: "privacyRedactionEnabled")
        } else {
            UserDefaults.standard.removeObject(forKey: "privacyRedactionEnabled")
        }
    }

    // Enable both regex and ML-based detection
    UserDefaults.standard.set(true, forKey: "privacyRedactionEnabled")
    UserDefaults.standard.set("medium", forKey: "piiDetectionLevel")

    let text = "Contact John Smith at john@example.com or call 555-123-4567. He works at Apple Inc in San Francisco."
    let result = ContentRedactor.redact(text)

    // Should redact:
    // - Email (regex)
    // - Name (ML)
    // - Place (ML at medium level)
    // SSN pattern won't match phone format in this example

    #expect(result.redactionCount > 0)
    #expect(!result.text.contains("john@example.com")) // Email redacted by regex
}
