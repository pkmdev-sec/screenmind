import ApplicationServices
import Foundation

public actor AccessibilityTreeExtractor {
    private let maxDepth: Int = 30
    private let maxNodes: Int = 5000
    private let timeoutSeconds: TimeInterval = 0.25

    public init() {}

    /// Extract text from the focused window of the app with given PID.
    /// This is 10x faster than OCR for most native and Electron apps.
    /// Returns nil if extraction fails or times out.
    public nonisolated func extractText(from pid: pid_t) -> ExtractedText? {
        // Skip extraction if target is ScreenMind itself — querying our own
        // SwiftUI accessibility tree from a background actor causes MainActor
        // re-entry (EXC_BREAKPOINT via _dispatch_assert_queue_fail).
        guard pid != ProcessInfo.processInfo.processIdentifier else {
            return nil
        }

        let start = CFAbsoluteTimeGetCurrent()
        let app = AXUIElementCreateApplication(pid)

        // Enable enhanced UI for Chromium/Electron apps
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)

        // Get focused window
        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef) == .success else {
            return nil
        }
        // CFTypeRef → AXUIElement cast always succeeds for AX API results
        let window = windowRef as! AXUIElement

        var text = ""
        var nodeCount = 0
        var browserURL: String?

        traverseElement(window, depth: 0, text: &text, nodeCount: &nodeCount, url: &browserURL, startTime: start)

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        // Truncate to reasonable size (same as OCR: 4000 chars)
        let finalText = text.count > 4000 ? String(text.prefix(4000)) + "..." : text

        return ExtractedText(
            text: finalText,
            source: .accessibility,
            nodeCount: nodeCount,
            browserURL: browserURL,
            extractionTime: elapsed
        )
    }

    private nonisolated func traverseElement(
        _ element: AXUIElement,
        depth: Int,
        text: inout String,
        nodeCount: inout Int,
        url: inout String?,
        startTime: CFAbsoluteTime
    ) {
        guard depth < maxDepth, nodeCount < maxNodes else { return }
        guard CFAbsoluteTimeGetCurrent() - startTime < timeoutSeconds else { return }
        nodeCount += 1

        // Get role
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String ?? ""

        // Extract text from text-bearing roles
        let textRoles: Set<String> = ["AXStaticText", "AXTextField", "AXTextArea", "AXButton", "AXMenuItem", "AXLink", "AXHeading", "AXCell"]
        if textRoles.contains(role) {
            if let value = axStringValue(element, attribute: kAXValueAttribute)
                ?? axStringValue(element, attribute: kAXTitleAttribute)
                ?? axStringValue(element, attribute: kAXDescriptionAttribute) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    text.append(trimmed)
                    text.append("\n")
                }
            }
        }

        // Extract browser URL from document elements
        if url == nil {
            if let docURL = axStringValue(element, attribute: "AXURL")
                ?? axStringValue(element, attribute: "AXDocument") {
                if docURL.hasPrefix("http") {
                    url = docURL
                }
            }
        }

        // Recurse into children
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else { return }

        for child in children {
            traverseElement(child, depth: depth + 1, text: &text, nodeCount: &nodeCount, url: &url, startTime: startTime)
        }
    }

    private nonisolated func axStringValue(_ element: AXUIElement, attribute: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success else { return nil }
        return ref as? String
    }
}
