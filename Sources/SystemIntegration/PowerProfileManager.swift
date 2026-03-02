import Foundation
import Shared

/// Manages adaptive power profiles based on battery and thermal state.
public actor PowerProfileManager {
    private let powerMonitor = PowerStateMonitor()
    private let thermalMonitor = ThermalStateMonitor()
    private var currentMode: PowerMode = .performance

    public init() {}

    public func start() async {
        await thermalMonitor.startMonitoring()
    }

    public func stop() async {
        await thermalMonitor.stopMonitoring()
    }

    public func updateAndGetConfiguration() async -> PowerProfileConfiguration {
        // Force saver mode under thermal pressure
        if thermalMonitor.shouldForceSaver() {
            currentMode = .saver
            return .saver
        }

        // Check battery state
        let state = await powerMonitor.currentState()

        // On AC power: performance mode
        if !state.isOnBattery {
            currentMode = .performance
            return .performance
        }

        // On battery: adaptive based on charge level
        if state.batteryLevel > 40 {
            currentMode = .balanced
            return .balanced
        }

        // Low battery: saver mode
        currentMode = .saver
        return .saver
    }

    public func currentPowerMode() -> PowerMode {
        currentMode
    }
}
