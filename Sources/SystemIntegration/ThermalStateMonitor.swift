import Foundation
import Shared

/// Monitors thermal state to trigger power saver mode under thermal pressure.
public actor ThermalStateMonitor {
    private var observer: (any NSObjectProtocol)?

    public init() {}

    public func startMonitoring() {
        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.handleThermalChange() }
        }
    }

    public func stopMonitoring() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }

    public nonisolated func currentState() -> ProcessInfo.ThermalState {
        ProcessInfo.processInfo.thermalState
    }

    public nonisolated func shouldForceSaver() -> Bool {
        let state = ProcessInfo.processInfo.thermalState
        return state == .serious || state == .critical
    }

    private func handleThermalChange() {
        let state = ProcessInfo.processInfo.thermalState
        SMLogger.system.warning("Thermal state changed: \(String(describing: state))")
    }
}
