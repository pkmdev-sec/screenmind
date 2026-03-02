import Foundation
import Testing
@testable import PipelineCore
@testable import Shared

// MARK: - GDPR Data Export Tests

@Suite(.serialized) struct ComplianceTests {

@Test func auditLoggerGDPRExport() async throws {
    let logger = AuditLogger()

    // Log some test entries
    await logger.log(action: .captured, appName: "Safari", reason: "Test capture")
    await logger.log(action: .skipped, appName: "Xcode", reason: "Build notification")

    // Export GDPR data
    let exportPath = try await logger.exportGDPRData()

    #expect(!exportPath.isEmpty)
    #expect(exportPath.contains("gdpr-export"))

    // Verify file exists
    #expect(FileManager.default.fileExists(atPath: exportPath))

    // Read and verify JSON structure
    let data = try Data(contentsOf: URL(fileURLWithPath: exportPath))
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json?["audit_logs"] != nil)
    #expect(json?["settings"] != nil)
    #expect(json?["export_metadata"] != nil)

    // Clean up
    try? FileManager.default.removeItem(atPath: exportPath)
}

@Test func auditLoggerDataRetentionPolicy() async throws {
    let logger = AuditLogger()

    // Set retention policy to 0 days (disabled)
    UserDefaults.standard.dataRetentionDays = 0
    let deletedCount1 = try await logger.applyDataRetentionPolicy()
    #expect(deletedCount1 == 0)

    // Set retention policy to 30 days
    UserDefaults.standard.dataRetentionDays = 30
    let deletedCount2 = try await logger.applyDataRetentionPolicy()
    // Should not throw, count may be 0 if no old logs
    #expect(deletedCount2 >= 0)
}

@Test func auditLoggerComplianceReport() async {
    let logger = AuditLogger()

    // Log some entries
    await logger.log(action: .captured, appName: "Safari", reason: "Test")
    await logger.log(action: .redacted, appName: "Slack", reason: "Privacy")

    let report = await logger.generateComplianceReport()

    #expect(report["data_retention"] != nil)
    #expect(report["action_breakdown"] != nil)
    #expect(report["privacy_controls"] != nil)
    #expect(report["report_generated_at"] != nil)
}

}

// MARK: - UserDefaults Tests

@Test func complianceModeUserDefaults() {
    UserDefaults.standard.complianceMode = true
    #expect(UserDefaults.standard.complianceMode == true)

    UserDefaults.standard.complianceMode = false
    #expect(UserDefaults.standard.complianceMode == false)
}

@Test func dataRetentionDaysUserDefaults() {
    UserDefaults.standard.dataRetentionDays = 30
    #expect(UserDefaults.standard.dataRetentionDays == 30)

    UserDefaults.standard.dataRetentionDays = 90
    #expect(UserDefaults.standard.dataRetentionDays == 90)
}

@Test func dataRetentionPolicyString() {
    UserDefaults.standard.dataRetentionDays = 0
    #expect(UserDefaults.standard.dataRetentionPolicy == "indefinite")

    UserDefaults.standard.dataRetentionDays = 30
    #expect(UserDefaults.standard.dataRetentionPolicy == "30_days")

    UserDefaults.standard.dataRetentionDays = 90
    #expect(UserDefaults.standard.dataRetentionPolicy == "90_days")

    UserDefaults.standard.dataRetentionDays = 365
    #expect(UserDefaults.standard.dataRetentionPolicy == "1_year")

    UserDefaults.standard.dataRetentionDays = 500
    #expect(UserDefaults.standard.dataRetentionPolicy == "custom_500_days")
}
