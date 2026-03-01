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
                "OCRProcessing",
                "AIProcessing",
                "StorageCore",
                "SystemIntegration"
            ],
            path: "Sources/PipelineCore"
        ),

        // MARK: - System Integration
        .target(
            name: "SystemIntegration",
            dependencies: ["Shared"],
            path: "Sources/SystemIntegration"
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
                "SystemIntegration"
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
            dependencies: ["SystemIntegration"],
            path: "Tests/SystemIntegrationTests"
        ),
    ]
)
