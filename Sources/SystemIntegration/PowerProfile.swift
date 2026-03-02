import Foundation

/// Power management modes for adaptive capture behavior.
public enum PowerMode: String, Sendable, CaseIterable, Codable {
    case performance
    case balanced
    case saver
}

/// Configuration parameters for each power mode.
public struct PowerProfileConfiguration: Sendable {
    public let minEventInterval: TimeInterval
    public let idleFallbackInterval: TimeInterval
    public let visualChangeThreshold: Double
    public let imageQuality: Float
    public let slowdownFactor: Double

    public static let performance = PowerProfileConfiguration(
        minEventInterval: 0.2,
        idleFallbackInterval: 30,
        visualChangeThreshold: 0.05,
        imageQuality: 0.8,
        slowdownFactor: 1.0
    )

    public static let balanced = PowerProfileConfiguration(
        minEventInterval: 0.5,
        idleFallbackInterval: 60,
        visualChangeThreshold: 0.10,
        imageQuality: 0.6,
        slowdownFactor: 2.0
    )

    public static let saver = PowerProfileConfiguration(
        minEventInterval: 1.0,
        idleFallbackInterval: 120,
        visualChangeThreshold: 0.15,
        imageQuality: 0.4,
        slowdownFactor: 4.0
    )

    public static func configuration(for mode: PowerMode) -> PowerProfileConfiguration {
        switch mode {
        case .performance:
            return .performance
        case .balanced:
            return .balanced
        case .saver:
            return .saver
        }
    }
}
