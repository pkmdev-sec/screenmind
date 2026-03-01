import Foundation
import Shared

/// Error boundary that isolates pipeline stage failures.
/// Prevents errors in one stage from crashing the entire pipeline.
public actor ErrorBoundary {

    public enum StageError: Error, Sendable {
        case stageFailure(stage: String, underlying: Error)
        case stageTimeout(stage: String, seconds: TimeInterval)
        case rateLimited(retryAfter: TimeInterval)
    }

    private var errorCounts: [String: Int] = [:]
    private var lastErrors: [String: Date] = [:]
    private let errorThreshold: Int
    private let cooldownInterval: TimeInterval

    public init(errorThreshold: Int = 10, cooldownInterval: TimeInterval = 3600) {
        self.errorThreshold = errorThreshold
        self.cooldownInterval = cooldownInterval
    }

    /// Record an error for a stage and check if the stage should be disabled.
    public func recordError(stage: String, error: Error) -> Bool {
        // Auto-reset if enough time has passed since last error (cooldown recovery)
        if let lastError = lastErrors[stage],
           Date.now.timeIntervalSince(lastError) > cooldownInterval {
            errorCounts[stage] = 0
            SMLogger.pipeline.info("[\(stage)] Error count reset after cooldown")
        }

        let count = (errorCounts[stage] ?? 0) + 1
        errorCounts[stage] = count
        lastErrors[stage] = Date()

        SMLogger.pipeline.error("[\(stage)] Error #\(count): \(error.localizedDescription)")

        if count >= errorThreshold {
            SMLogger.pipeline.error("[\(stage)] Error threshold reached (\(count)/\(self.errorThreshold)) — stage temporarily disabled")
            return true // Stage should be disabled
        }

        return false
    }

    /// Reset error count for a stage (e.g., after successful operation).
    public func resetErrors(stage: String) {
        errorCounts[stage] = 0
    }

    /// Get current error count for a stage.
    public func errorCount(stage: String) -> Int {
        errorCounts[stage] ?? 0
    }

    /// Execute with error boundary — catches errors and logs them without crashing.
    public func withBoundary<T: Sendable>(
        stage: String,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            let result = try await operation()
            await resetErrors(stage: stage)
            return result
        } catch {
            let shouldDisable = await recordError(stage: stage, error: error)
            if shouldDisable {
                SMLogger.pipeline.error("[\(stage)] Stage disabled due to repeated failures")
            }
            return fallback
        }
    }

    /// Execute with error boundary and optional retry strategy.
    public func withRetry<T: Sendable>(
        stage: String,
        strategy: RetryStrategy,
        fallback: T,
        operation: @Sendable () async throws -> T
    ) async -> T {
        do {
            let result = try await strategy.execute(operation: stage, operation)
            await resetErrors(stage: stage)
            return result
        } catch {
            let _ = await recordError(stage: stage, error: error)
            return fallback
        }
    }

    /// Get a summary of all errors across stages.
    public func summary() -> [String: Int] {
        errorCounts
    }
}
