import Foundation
import Carbon.HIToolbox
import Shared

/// Manages global keyboard shortcuts for ScreenMind.
///
/// Shortcuts:
/// - ⌘⇧N — Toggle monitoring
/// - ⌘⇧P — Pause / Resume
/// - ⌘⇧S — Open notes browser
public final class KeyboardShortcutsManager: @unchecked Sendable {

    public static let shared = KeyboardShortcutsManager()

    public enum ShortcutAction {
        case toggleMonitoring
        case togglePause
        case openNotesBrowser
        case openTimeline
        case manualCapture
        case voiceMemo
    }

    private var eventHandler: EventHandlerRef?
    private var actionCallback: ((ShortcutAction) -> Void)?

    private init() {}

    /// Register global hotkeys. Call from main thread.
    public func register(action: @escaping (ShortcutAction) -> Void) {
        self.actionCallback = action

        var hotKeyRef: EventHotKeyRef?
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        // ⌘⇧N — Toggle monitoring (keycode 45 = N)
        let hotKeyID1 = EventHotKeyID(signature: fourCharCode("SMn1"), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_N), modifiers, hotKeyID1, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // ⌘⇧P — Pause/Resume (keycode 35 = P)
        let hotKeyID2 = EventHotKeyID(signature: fourCharCode("SMn2"), id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_P), modifiers, hotKeyID2, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // ⌘⇧S — Open notes browser (keycode 1 = S)
        let hotKeyID3 = EventHotKeyID(signature: fourCharCode("SMn3"), id: 3)
        RegisterEventHotKey(UInt32(kVK_ANSI_S), modifiers, hotKeyID3, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // ⌘⇧T — Open timeline (keycode 17 = T)
        let hotKeyID4 = EventHotKeyID(signature: fourCharCode("SMn4"), id: 4)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), modifiers, hotKeyID4, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // ⌘⌥⇧C — Manual capture (keycode 8 = C, with Option key to avoid conflicts)
        let captureModifiers: UInt32 = UInt32(cmdKey | shiftKey | optionKey)
        let hotKeyID5 = EventHotKeyID(signature: fourCharCode("SMn5"), id: 5)
        RegisterEventHotKey(UInt32(kVK_ANSI_C), captureModifiers, hotKeyID5, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // ⌘⌥⇧V — Voice memo (keycode 9 = V)
        let hotKeyID6 = EventHotKeyID(signature: fourCharCode("SMn6"), id: 6)
        RegisterEventHotKey(UInt32(kVK_ANSI_V), captureModifiers, hotKeyID6, GetEventDispatcherTarget(), 0, &hotKeyRef)

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }

            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            let manager = KeyboardShortcutsManager.shared
            switch hotKeyID.id {
            case 1: manager.actionCallback?(.toggleMonitoring)
            case 2: manager.actionCallback?(.togglePause)
            case 3: manager.actionCallback?(.openNotesBrowser)
            case 4: manager.actionCallback?(.openTimeline)
            case 5: manager.actionCallback?(.manualCapture)
            case 6: manager.actionCallback?(.voiceMemo)
            default: break
            }

            return noErr
        }

        InstallEventHandler(GetEventDispatcherTarget(), handler, 1, &eventType, nil, &eventHandler)
        SMLogger.system.info("Global keyboard shortcuts registered")
    }

    private func fourCharCode(_ string: String) -> OSType {
        var result: OSType = 0
        for char in string.utf8.prefix(4) {
            result = (result << 8) | OSType(char)
        }
        return result
    }
}
