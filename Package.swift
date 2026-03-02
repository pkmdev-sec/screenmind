// swift-tools-version: 5.10
// ScreenMind — AI-Powered Screen Memory for macOS

import PackageDescription

let package = Package(
    name: "ScreenMind",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ScreenMind", targets: ["ScreenMindApp"]),
        .executable(name: "screenmind-cli", targets: ["ScreenMindCLI"])
    ],
    targets: [
        // MARK: - Shared Foundation
        .target(
            name: "Shared",
            path: "Sources/Shared"
        ),

        // MARK: - Core Pipeline Modules
        .target(
            name: "CaptureCore",
            dependencies: ["Shared"],
            path: "Sources/CaptureCore"
        ),
        .target(
            name: "ChangeDetection",
            dependencies: ["Shared", "CaptureCore"],
            path: "Sources/ChangeDetection"
        ),
        .target(
            name: "AccessibilityExtraction",
            dependencies: ["Shared"],
            path: "Sources/AccessibilityExtraction"
        ),
        .target(
            name: "OCRProcessing",
            dependencies: ["Shared", "ChangeDetection"],
            path: "Sources/OCRProcessing"
        ),
        .target(
            name: "AIProcessing",
            dependencies: ["Shared", "OCRProcessing"],
            path: "Sources/AIProcessing"
        ),
        .target(
            name: "StorageCore",
            dependencies: ["Shared", "AIProcessing"],
            path: "Sources/StorageCore"
        ),

        // MARK: - Orchestration
        .target(
            name: "PipelineCore",
            dependencies: [
                "Shared",
                "CaptureCore",
                "ChangeDetection",
                "AccessibilityExtraction",
                "OCRProcessing",
                "AIProcessing",
                "StorageCore",
                "SystemIntegration",
                "AudioCore",
                "SemanticSearch",
                "PluginSystem"
            ],
            path: "Sources/PipelineCore"
        ),

        // MARK: - Audio Intelligence
        .target(
            name: "AudioCore",
            dependencies: ["Shared"],
            path: "Sources/AudioCore"
        ),

        // MARK: - Semantic Search
        .target(
            name: "SemanticSearch",
            dependencies: ["Shared", "StorageCore"],
            path: "Sources/SemanticSearch"
        ),

        // MARK: - Plugin System
        .target(
            name: "PluginSystem",
            dependencies: ["Shared", "StorageCore"],
            path: "Sources/PluginSystem"
        ),

        // MARK: - System Integration
        .target(
            name: "SystemIntegration",
            dependencies: ["Shared"],
            path: "Sources/SystemIntegration"
        ),

        // MARK: - Test Utilities
        .target(
            name: "TestUtilities",
            dependencies: ["AIProcessing"],
            path: "Sources/TestUtilities"
        ),

        // MARK: - Main App
        .executableTarget(
            name: "ScreenMindApp",
            dependencies: [
                "Shared",
                "CaptureCore",
                "ChangeDetection",
                "OCRProcessing",
                "AIProcessing",
                "StorageCore",
                "PipelineCore",
                "SystemIntegration",
                "AudioCore",
                "SemanticSearch",
                "PluginSystem"
            ],
            path: "Sources/ScreenMindApp"
        ),

        // MARK: - CLI Tool
        .executableTarget(
            name: "ScreenMindCLI",
            dependencies: [
                "Shared",
                "StorageCore",
                "AIProcessing",
                "SystemIntegration"
            ],
            path: "Sources/ScreenMindCLI"
        ),

        // MARK: - Tests
        .testTarget(
            name: "SharedTests",
            dependencies: ["Shared"],
            path: "Tests/SharedTests"
        ),
        .testTarget(
            name: "CaptureCoreTests",
            dependencies: ["CaptureCore"],
            path: "Tests/CaptureCoreTests"
        ),
        .testTarget(
            name: "ChangeDetectionTests",
            dependencies: ["ChangeDetection"],
            path: "Tests/ChangeDetectionTests"
        ),
        .testTarget(
            name: "OCRProcessingTests",
            dependencies: ["OCRProcessing"],
            path: "Tests/OCRProcessingTests"
        ),
        .testTarget(
            name: "AIProcessingTests",
            dependencies: ["AIProcessing"],
            path: "Tests/AIProcessingTests"
        ),
        .testTarget(
            name: "StorageCoreTests",
            dependencies: ["StorageCore"],
            path: "Tests/StorageCoreTests"
        ),
        .testTarget(
            name: "PipelineCoreTests",
            dependencies: ["PipelineCore"],
            path: "Tests/PipelineCoreTests"
        ),
        .testTarget(
            name: "SystemIntegrationTests",
            dependencies: ["SystemIntegration", "TestUtilities"],
            path: "Tests/SystemIntegrationTests"
        ),
        .testTarget(
            name: "AudioCoreTests",
            dependencies: ["AudioCore"],
            path: "Tests/AudioCoreTests"
        ),
        .testTarget(
            name: "SemanticSearchTests",
            dependencies: ["SemanticSearch"],
            path: "Tests/SemanticSearchTests"
        ),
        .testTarget(
            name: "PluginSystemTests",
            dependencies: ["PluginSystem"],
            path: "Tests/PluginSystemTests"
        ),
    ]
)
