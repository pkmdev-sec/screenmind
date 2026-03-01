import Foundation
import Shared

/// Configurable retry strategy with exponential backoff.
public struct RetryStrategy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        multiplier: Double = 2.0
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }

    /// Calculate delay for a given attempt (0-indexed).
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(multiplier, Double(attempt))
        return min(delay, maxDelay)
    }

    /// Execute an async operation with retry logic.
    public func execute<T: Sendable>(
        operation: String = "operation",
        _ body: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                return try await body()
            } catch {
                lastError = error

                if attempt < maxAttempts - 1 {
                    let wait = delay(forAttempt: attempt)
                    SMLogger.pipeline.warning(
                        "\(operation) failed (attempt \(attempt + 1)/\(self.maxAttempts)): \(error.localizedDescription). Retrying in \(wait)s"
                    )
                    try await Task.sleep(for: .seconds(wait))
                } else {
                    SMLogger.pipeline.error(
                        "\(operation) failed after \(self.maxAttempts) attempts: \(error.localizedDescription)"
                    )
                }
            }
        }

        throw lastError!
    }

    // MARK: - Presets

    /// Strategy for AI API calls — more retries, longer backoff.
    public static let aiAPI = RetryStrategy(maxAttempts: 3, baseDelay: 2.0, maxDelay: 60.0, multiplier: 3.0)

    /// Strategy for storage operations — quick retries.
    public static let storage = RetryStrategy(maxAttempts: 2, baseDelay: 0.5, maxDelay: 5.0, multiplier: 2.0)

    /// Strategy for OCR — single retry with short delay.
    public static let ocr = RetryStrategy(maxAttempts: 2, baseDelay: 1.0, maxDelay: 5.0, multiplier: 2.0)
}
