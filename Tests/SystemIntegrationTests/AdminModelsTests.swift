import Foundation
import Testing
@testable import SystemIntegration

// MARK: - Admin Dashboard Tests

@Test func adminDashboardEmpty() {
    let dashboard = AdminDashboard.empty()

    #expect(dashboard.systemStats.totalNotes == 0)
    #expect(dashboard.userStats.avgNotesPerUser == 0.0)
    #expect(dashboard.storageStats.totalUsedBytes == 0)
}

// MARK: - Storage Stats Tests

@Test func storageStatsUtilization() {
    let stats = StorageStatsDetail(
        totalUsedBytes: 500_000_000, // 500 MB
        totalQuotaBytes: 1_000_000_000, // 1 GB
        breakdown: .empty(),
        usersNearQuota: []
    )

    #expect(stats.utilizationPercent == 50.0)
}

@Test func storageStatsZeroQuota() {
    let stats = StorageStatsDetail(
        totalUsedBytes: 1000,
        totalQuotaBytes: 0,
        breakdown: .empty(),
        usersNearQuota: []
    )

    #expect(stats.utilizationPercent == 0.0)
}

// MARK: - User Quota Tests

@Test func userQuotaDefault() {
    let quota = UserQuota.defaultQuota(userID: "user-1")

    #expect(quota.userID == "user-1")
    #expect(quota.storageQuotaBytes == 1_073_741_824)
    #expect(quota.maxNotes == 1000)
    #expect(quota.maxAPIRequestsPerHour == 100)
    #expect(quota.maxConcurrentSessions == 3)
}

@Test func userQuotaPro() {
    let quota = UserQuota.proQuota(userID: "user-1")

    #expect(quota.userID == "user-1")
    #expect(quota.storageQuotaBytes == 107_374_182_400)
    #expect(quota.maxNotes == 100_000)
    #expect(quota.maxAPIRequestsPerHour == 1000)
    #expect(quota.maxConcurrentSessions == 10)
}

@Test func userQuotaStatusUtilization() {
    let status = UserQuotaStatus(
        userID: "user-1",
        userName: "Alice",
        usedBytes: 750_000_000,
        quotaBytes: 1_000_000_000
    )

    #expect(status.utilizationPercent == 75.0)
}

// MARK: - Usage Analytics Tests

@Test func usageAnalyticsInit() {
    let analytics = UsageAnalytics(
        entityID: "user-1",
        period: .week,
        notesCreated: 50,
        avgNotesPerDay: 7.14,
        topApps: [
            AppUsage(appName: "Xcode", noteCount: 30, percentage: 60.0),
            AppUsage(appName: "Safari", noteCount: 20, percentage: 40.0)
        ],
        topCategories: [
            CategoryUsage(category: "coding", noteCount: 35, percentage: 70.0),
            CategoryUsage(category: "research", noteCount: 15, percentage: 30.0)
        ],
        storageUsedBytes: 100_000_000,
        apiRequestsMade: 500
    )

    #expect(analytics.entityID == "user-1")
    #expect(analytics.period == .week)
    #expect(analytics.notesCreated == 50)
    #expect(analytics.topApps.count == 2)
    #expect(analytics.topCategories.count == 2)
}

// MARK: - Billing Info Tests

@Test func billingInfoFreePlan() {
    let billing = BillingInfo.freePlan(entityID: "user-1")

    #expect(billing.entityID == "user-1")
    #expect(billing.plan == .free)
    #expect(billing.status == .active)
    #expect(billing.billingAmountCents == 0)
    #expect(billing.nextBillingDate == nil)
}

@Test func subscriptionPlanEnumCases() {
    #expect(SubscriptionPlan.free.rawValue == "free")
    #expect(SubscriptionPlan.pro.rawValue == "pro")
    #expect(SubscriptionPlan.team.rawValue == "team")
    #expect(SubscriptionPlan.enterprise.rawValue == "enterprise")
}

@Test func subscriptionStatusEnumCases() {
    #expect(SubscriptionStatus.active.rawValue == "active")
    #expect(SubscriptionStatus.trialing.rawValue == "trialing")
    #expect(SubscriptionStatus.pastDue.rawValue == "past_due")
    #expect(SubscriptionStatus.canceled.rawValue == "canceled")
    #expect(SubscriptionStatus.expired.rawValue == "expired")
}

// MARK: - Performance Metrics Tests

@Test func performanceMetricsEmpty() {
    let metrics = PerformanceMetrics.empty()

    #expect(metrics.avgApiResponseMs == 0.0)
    #expect(metrics.avgOCRProcessingMs == 0.0)
    #expect(metrics.avgAIProcessingMs == 0.0)
    #expect(metrics.errorRate == 0.0)
}

@Test func performanceMetricsInit() {
    let metrics = PerformanceMetrics(
        avgApiResponseMs: 25.5,
        avgOCRProcessingMs: 150.0,
        avgAIProcessingMs: 800.0,
        errorRate: 0.02,
        cpuUsagePercent: 3.5,
        memoryUsageMB: 85
    )

    #expect(metrics.avgApiResponseMs == 25.5)
    #expect(metrics.errorRate == 0.02)
    #expect(metrics.cpuUsagePercent == 3.5)
}
