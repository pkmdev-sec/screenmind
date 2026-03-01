import Foundation
import IOKit.ps
import Shared

/// Monitors battery state and power events to pause capture on low battery.
public actor PowerStateMonitor {

    public struct PowerState: Sendable {
        public let isOnBattery: Bool
        public let batteryLevel: Int
        public let isLowPower: Bool

        public init(isOnBattery: Bool, batteryLevel: Int, isLowPower: Bool) {
            self.isOnBattery = isOnBattery
            self.batteryLevel = batteryLevel
            self.isLowPower = isLowPower
        }
    }

    private let lowBatteryThreshold: Int

    public init(lowBatteryThreshold: Int = AppConstants.Resources.lowBatteryPauseThreshold) {
        self.lowBatteryThreshold = lowBatteryThreshold
    }

    /// Get the current power state.
    public func currentState() -> PowerState {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        guard let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            // Desktop Mac — always on AC
            return PowerState(isOnBattery: false, batteryLevel: 100, isLowPower: false)
        }

        let isCharging = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        let capacity = info[kIOPSCurrentCapacityKey] as? Int ?? 100

        let state = PowerState(
            isOnBattery: !isCharging,
            batteryLevel: capacity,
            isLowPower: !isCharging && capacity <= lowBatteryThreshold
        )

        return state
    }

    /// Check if monitoring should be paused due to low battery.
    public func shouldPauseForBattery() -> Bool {
        let state = currentState()
        if state.isLowPower {
            SMLogger.system.warning("Low battery (\(state.batteryLevel)%) — suggesting pause")
            return true
        }
        return false
    }
}
