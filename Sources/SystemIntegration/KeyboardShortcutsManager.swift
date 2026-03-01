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
