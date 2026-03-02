import Foundation

/// Admin dashboard aggregate model.
/// Provides high-level overview of system usage, performance, and health
/// for enterprise deployments with multiple users.
public struct AdminDashboard: Codable, Sendable {
    /// Dashboard timestamp
    public let timestamp: Date
    /// System-wide statistics
    public let systemStats: SystemStats
    /// User statistics
    public let userStats: UserStats
    /// Storage statistics
    public let storageStats: StorageStatsDetail
    /// Performance metrics
    public let performance: PerformanceMetrics
    /// Recent activity
    public let recentActivity: [ActivitySummary]

    public init(
        timestamp: Date,
        systemStats: SystemStats,
        userStats: UserStats,
        storageStats: StorageStatsDetail,
        performance: PerformanceMetrics,
        recentActivity: [ActivitySummary]
    ) {
        self.timestamp = timestamp
        self.systemStats = systemStats
        self.userStats = userStats
        self.storageStats = storageStats
        self.performance = performance
        self.recentActivity = recentActivity
    }

    /// Generate empty dashboard (for demo/stub).
    public static func empty() -> AdminDashboard {
        return AdminDashboard(
            timestamp: Date(),
            systemStats: SystemStats.empty(),
            userStats: UserStats.empty(),
            storageStats: StorageStatsDetail.empty(),
            performance: PerformanceMetrics.empty(),
            recentActivity: []
        )
    }
}

/// System-wide statistics.
public struct SystemStats: Codable, Sendable {
    /// Total notes across all users
    public let totalNotes: Int
    /// Total users
    public let totalUsers: Int
    /// Active users (last 7 days)
    public let activeUsers: Int
    /// Total workspaces
    public let totalWorkspaces: Int
    /// System uptime in seconds
    public let uptimeSeconds: Int
    /// App version
    public let appVersion: String

    public init(
        totalNotes: Int,
        totalUsers: Int,
        activeUsers: Int,
        totalWorkspaces: Int,
        uptimeSeconds: Int,
        appVersion: String
    ) {
        self.totalNotes = totalNotes
        self.totalUsers = totalUsers
        self.activeUsers = activeUsers
        self.totalWorkspaces = totalWorkspaces
        self.uptimeSeconds = uptimeSeconds
        self.appVersion = appVersion
    }

    public static func empty() -> SystemStats {
        return SystemStats(
            totalNotes: 0,
            totalUsers: 0,
            activeUsers: 0,
            totalWorkspaces: 0,
            uptimeSeconds: 0,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )
    }
}

/// User statistics.
public struct UserStats: Codable, Sendable {
    /// Average notes per user
    public let avgNotesPerUser: Double
    /// Most active user
    public let mostActiveUser: String?
    /// User growth (last 30 days)
    public let userGrowth: Int
    /// Total user sessions
    public let totalSessions: Int
    /// Average session duration (seconds)
    public let avgSessionDuration: Double

    public init(
        avgNotesPerUser: Double,
        mostActiveUser: String?,
        userGrowth: Int,
        totalSessions: Int,
        avgSessionDuration: Double
    ) {
        self.avgNotesPerUser = avgNotesPerUser
        self.mostActiveUser = mostActiveUser
        self.userGrowth = userGrowth
        self.totalSessions = totalSessions
        self.avgSessionDuration = avgSessionDuration
    }

    public static func empty() -> UserStats {
        return UserStats(
            avgNotesPerUser: 0.0,
            mostActiveUser: nil,
            userGrowth: 0,
            totalSessions: 0,
            avgSessionDuration: 0.0
        )
    }
}

/// Detailed storage statistics.
public struct StorageStatsDetail: Codable, Sendable {
    /// Total storage used (bytes)
    public let totalUsedBytes: Int64
    /// Total storage quota (bytes)
    public let totalQuotaBytes: Int64
    /// Storage breakdown by type
    public let breakdown: StorageBreakdown
    /// Users approaching quota
    public let usersNearQuota: [UserQuotaStatus]

    public init(
        totalUsedBytes: Int64,
        totalQuotaBytes: Int64,
        breakdown: StorageBreakdown,
        usersNearQuota: [UserQuotaStatus]
    ) {
        self.totalUsedBytes = totalUsedBytes
        self.totalQuotaBytes = totalQuotaBytes
        self.breakdown = breakdown
        self.usersNearQuota = usersNearQuota
    }

    /// Storage utilization percentage.
    public var utilizationPercent: Double {
        guard totalQuotaBytes > 0 else { return 0.0 }
        return Double(totalUsedBytes) / Double(totalQuotaBytes) * 100.0
    }

    public static func empty() -> StorageStatsDetail {
        return StorageStatsDetail(
            totalUsedBytes: 0,
            totalQuotaBytes: 1_073_741_824, // 1 GB default
            breakdown: StorageBreakdown.empty(),
            usersNearQuota: []
        )
    }
}

/// Storage breakdown by type.
public struct StorageBreakdown: Codable, Sendable {
    /// Screenshots storage (bytes)
    public let screenshotsBytes: Int64
    /// Database storage (bytes)
    public let databaseBytes: Int64
    /// Thumbnails storage (bytes)
    public let thumbnailsBytes: Int64
    /// Other storage (bytes)
    public let otherBytes: Int64

    public init(
        screenshotsBytes: Int64,
        databaseBytes: Int64,
        thumbnailsBytes: Int64,
        otherBytes: Int64
    ) {
        self.screenshotsBytes = screenshotsBytes
        self.databaseBytes = databaseBytes
        self.thumbnailsBytes = thumbnailsBytes
        self.otherBytes = otherBytes
    }

    public static func empty() -> StorageBreakdown {
        return StorageBreakdown(
            screenshotsBytes: 0,
            databaseBytes: 0,
            thumbnailsBytes: 0,
            otherBytes: 0
        )
    }
}

/// User quota status.
public struct UserQuotaStatus: Codable, Sendable {
    /// User ID
    public let userID: String
    /// User name
    public let userName: String
    /// Storage used (bytes)
    public let usedBytes: Int64
    /// Storage quota (bytes)
    public let quotaBytes: Int64
    /// Utilization percentage
    public var utilizationPercent: Double {
        guard quotaBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(quotaBytes) * 100.0
    }

    public init(
        userID: String,
        userName: String,
        usedBytes: Int64,
        quotaBytes: Int64
    ) {
        self.userID = userID
        self.userName = userName
        self.usedBytes = usedBytes
        self.quotaBytes = quotaBytes
    }
}

/// Performance metrics for monitoring.
public struct PerformanceMetrics: Codable, Sendable {
    /// Average API response time (ms)
    public let avgApiResponseMs: Double
    /// Average OCR processing time (ms)
    public let avgOCRProcessingMs: Double
    /// Average AI processing time (ms)
    public let avgAIProcessingMs: Double
    /// Error rate (0.0 to 1.0)
    public let errorRate: Double
    /// CPU usage percentage (0.0 to 100.0)
    public let cpuUsagePercent: Double
    /// Memory usage (MB)
    public let memoryUsageMB: Int

    public init(
        avgApiResponseMs: Double,
        avgOCRProcessingMs: Double,
        avgAIProcessingMs: Double,
        errorRate: Double,
        cpuUsagePercent: Double,
        memoryUsageMB: Int
    ) {
        self.avgApiResponseMs = avgApiResponseMs
        self.avgOCRProcessingMs = avgOCRProcessingMs
        self.avgAIProcessingMs = avgAIProcessingMs
        self.errorRate = errorRate
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsageMB = memoryUsageMB
    }

    public static func empty() -> PerformanceMetrics {
        return PerformanceMetrics(
            avgApiResponseMs: 0.0,
            avgOCRProcessingMs: 0.0,
            avgAIProcessingMs: 0.0,
            errorRate: 0.0,
            cpuUsagePercent: 0.0,
            memoryUsageMB: 0
        )
    }
}

/// Activity summary for dashboard.
public struct ActivitySummary: Codable, Sendable, Identifiable {
    /// Unique activity ID
    public let id: String
    /// Activity type
    public let type: String
    /// User who performed action
    public let userName: String
    /// Activity description
    public let description: String
    /// Timestamp
    public let timestamp: Date

    public init(
        id: String,
        type: String,
        userName: String,
        description: String,
        timestamp: Date
    ) {
        self.id = id
        self.type = type
        self.userName = userName
        self.description = description
        self.timestamp = timestamp
    }
}

// MARK: - User Quota Management

/// Per-user quota configuration.
public struct UserQuota: Codable, Sendable {
    /// User ID
    public let userID: String
    /// Storage quota (bytes)
    public let storageQuotaBytes: Int64
    /// Max notes allowed
    public let maxNotes: Int
    /// Max API requests per hour
    public let maxAPIRequestsPerHour: Int
    /// Max concurrent sessions
    public let maxConcurrentSessions: Int
    /// Quota reset date
    public let quotaResetAt: Date?

    public init(
        userID: String,
        storageQuotaBytes: Int64,
        maxNotes: Int,
        maxAPIRequestsPerHour: Int,
        maxConcurrentSessions: Int,
        quotaResetAt: Date?
    ) {
        self.userID = userID
        self.storageQuotaBytes = storageQuotaBytes
        self.maxNotes = maxNotes
        self.maxAPIRequestsPerHour = maxAPIRequestsPerHour
        self.maxConcurrentSessions = maxConcurrentSessions
        self.quotaResetAt = quotaResetAt
    }

    /// Default quota (free tier).
    public static func defaultQuota(userID: String) -> UserQuota {
        return UserQuota(
            userID: userID,
            storageQuotaBytes: 1_073_741_824, // 1 GB
            maxNotes: 1000,
            maxAPIRequestsPerHour: 100,
            maxConcurrentSessions: 3,
            quotaResetAt: nil
        )
    }

    /// Pro quota (paid tier).
    public static func proQuota(userID: String) -> UserQuota {
        return UserQuota(
            userID: userID,
            storageQuotaBytes: 107_374_182_400, // 100 GB
            maxNotes: 100_000,
            maxAPIRequestsPerHour: 1000,
            maxConcurrentSessions: 10,
            quotaResetAt: nil
        )
    }
}

// MARK: - Usage Analytics

/// Usage analytics for individual user or workspace.
public struct UsageAnalytics: Codable, Sendable {
    /// User or workspace ID
    public let entityID: String
    /// Time period
    public let period: AnalyticsPeriod
    /// Notes created in period
    public let notesCreated: Int
    /// Notes per day average
    public let avgNotesPerDay: Double
    /// Top apps used
    public let topApps: [AppUsage]
    /// Top categories
    public let topCategories: [CategoryUsage]
    /// Total storage used (bytes)
    public let storageUsedBytes: Int64
    /// API requests made
    public let apiRequestsMade: Int

    public init(
        entityID: String,
        period: AnalyticsPeriod,
        notesCreated: Int,
        avgNotesPerDay: Double,
        topApps: [AppUsage],
        topCategories: [CategoryUsage],
        storageUsedBytes: Int64,
        apiRequestsMade: Int
    ) {
        self.entityID = entityID
        self.period = period
        self.notesCreated = notesCreated
        self.avgNotesPerDay = avgNotesPerDay
        self.topApps = topApps
        self.topCategories = topCategories
        self.storageUsedBytes = storageUsedBytes
        self.apiRequestsMade = apiRequestsMade
    }
}

/// Analytics time period.
public enum AnalyticsPeriod: String, Codable, Sendable {
    case day
    case week
    case month
    case quarter
    case year
}

/// App usage statistics.
public struct AppUsage: Codable, Sendable {
    /// App name
    public let appName: String
    /// Note count
    public let noteCount: Int
    /// Percentage of total notes
    public let percentage: Double

    public init(appName: String, noteCount: Int, percentage: Double) {
        self.appName = appName
        self.noteCount = noteCount
        self.percentage = percentage
    }
}

/// Category usage statistics.
public struct CategoryUsage: Codable, Sendable {
    /// Category name
    public let category: String
    /// Note count
    public let noteCount: Int
    /// Percentage of total notes
    public let percentage: Double

    public init(category: String, noteCount: Int, percentage: Double) {
        self.category = category
        self.noteCount = noteCount
        self.percentage = percentage
    }
}

// MARK: - Billing Information (Stub)

/// Billing information for subscription management.
/// Integrates with Stripe, Paddle, or other payment processors.
public struct BillingInfo: Codable, Sendable {
    /// User or workspace ID
    public let entityID: String
    /// Subscription plan
    public let plan: SubscriptionPlan
    /// Subscription status
    public let status: SubscriptionStatus
    /// Next billing date
    public let nextBillingDate: Date?
    /// Billing amount (in cents)
    public let billingAmountCents: Int
    /// Currency code (USD, EUR, etc.)
    public let currency: String
    /// Payment method (last 4 digits)
    public let paymentMethodLast4: String?

    public init(
        entityID: String,
        plan: SubscriptionPlan,
        status: SubscriptionStatus,
        nextBillingDate: Date?,
        billingAmountCents: Int,
        currency: String,
        paymentMethodLast4: String?
    ) {
        self.entityID = entityID
        self.plan = plan
        self.status = status
        self.nextBillingDate = nextBillingDate
        self.billingAmountCents = billingAmountCents
        self.currency = currency
        self.paymentMethodLast4 = paymentMethodLast4
    }

    /// Free plan (stub).
    public static func freePlan(entityID: String) -> BillingInfo {
        return BillingInfo(
            entityID: entityID,
            plan: .free,
            status: .active,
            nextBillingDate: nil,
            billingAmountCents: 0,
            currency: "USD",
            paymentMethodLast4: nil
        )
    }
}

/// Subscription plan tiers.
public enum SubscriptionPlan: String, Codable, Sendable {
    case free
    case pro
    case team
    case enterprise
}

/// Subscription status.
public enum SubscriptionStatus: String, Codable, Sendable {
    case active
    case trialing
    case pastDue = "past_due"
    case canceled
    case expired
}
