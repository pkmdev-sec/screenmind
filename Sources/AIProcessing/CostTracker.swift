import Foundation
import Shared

public actor CostTracker {
    public static let shared = CostTracker()
    private var inputTokens: Int = 0
    private var outputTokens: Int = 0
    private var requests: Int = 0
    private var sessionStart: Date = .now

    public func recordRequest(input: Int, output: Int) {
        inputTokens += input; outputTokens += output; requests += 1
    }

    public func estimatedCost(inputPrice: Double = 3.0, outputPrice: Double = 15.0) -> Double {
        (Double(inputTokens) / 1_000_000 * inputPrice) + (Double(outputTokens) / 1_000_000 * outputPrice)
    }

    public func stats() -> CostStats {
        CostStats(inputTokens: inputTokens, outputTokens: outputTokens, requestCount: requests, estimatedCost: estimatedCost(), sessionStart: sessionStart)
    }

    public func reset() { inputTokens = 0; outputTokens = 0; requests = 0; sessionStart = .now }
}

public struct CostStats: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let requestCount: Int
    public let estimatedCost: Double
    public let sessionStart: Date
}
