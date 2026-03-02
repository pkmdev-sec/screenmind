import Foundation
import Shared

/// Workflow automation engine — if-this-then-that rules for note events.
public actor WorkflowEngine {
    public static let shared = WorkflowEngine()

    private var rules: [WorkflowRule] = []

    private init() {
        // Load rules synchronously in init (safe because init is not re-entrant)
        if let data = UserDefaults.standard.data(forKey: "workflowRules"),
           let decoded = try? JSONDecoder().decode([WorkflowRule].self, from: data) {
            self.rules = decoded
        }
    }

    /// Evaluate all rules against a note event.
    public func evaluate(event: WorkflowEvent) async {
        for rule in rules where rule.enabled {
            if matches(rule: rule, event: event) {
                await execute(action: rule.action, event: event)
                SMLogger.pipeline.info("Workflow triggered: \(rule.name)")
            }
        }
    }

    // MARK: - Rule Management

    public func addRule(_ rule: WorkflowRule) {
        rules.append(rule)
        saveRules()
    }

    public func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules()
    }

    public func toggleRule(id: UUID) {
        if let index = rules.firstIndex(where: { $0.id == id }) {
            rules[index].enabled.toggle()
            saveRules()
        }
    }

    public var allRules: [WorkflowRule] { rules }

    // MARK: - Matching

    private func matches(rule: WorkflowRule, event: WorkflowEvent) -> Bool {
        switch rule.trigger {
        case .noteCreated:
            return true
        case .categoryIs(let category):
            return event.category == category
        case .appIs(let appName):
            return event.appName.localizedCaseInsensitiveContains(appName)
        case .tagContains(let tag):
            return event.tags.contains(tag)
        case .titleContains(let text):
            return event.title.localizedCaseInsensitiveContains(text)
        case .confidenceAbove(let threshold):
            return event.confidence > threshold
        }
    }

    // MARK: - Actions

    private func execute(action: WorkflowAction, event: WorkflowEvent) async {
        switch action {
        case .addTag(let tag):
            // Tags are added via the workflow system (caller handles persistence)
            SMLogger.pipeline.info("Workflow: add tag '\(tag)' to note")
        case .webhook(let url):
            await sendWebhook(url: url, event: event)
        case .notify(let message):
            // Post local notification
            let notificationMsg = message.replacingOccurrences(of: "{title}", with: event.title)
                .replacingOccurrences(of: "{app}", with: event.appName)
            SMLogger.pipeline.info("Workflow notification: \(notificationMsg)")
        case .exportToFolder(let path):
            SMLogger.pipeline.info("Workflow: export to \(path)")
        }
    }

    private func sendWebhook(url: String, event: WorkflowEvent) async {
        guard let requestURL = URL(string: url) else { return }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "title": event.title,
            "summary": event.summary,
            "category": event.category,
            "app": event.appName,
            "tags": event.tags,
            "source": "screenmind-workflow"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Persistence

    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: "workflowRules")
        }
    }
}

/// A workflow rule.
public struct WorkflowRule: Codable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var trigger: WorkflowTrigger
    public var action: WorkflowAction
    public var enabled: Bool

    public init(name: String, trigger: WorkflowTrigger, action: WorkflowAction, enabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.trigger = trigger
        self.action = action
        self.enabled = enabled
    }
}

/// Workflow triggers (conditions).
public enum WorkflowTrigger: Codable, Sendable {
    case noteCreated
    case categoryIs(String)
    case appIs(String)
    case tagContains(String)
    case titleContains(String)
    case confidenceAbove(Double)
}

/// Workflow actions.
public enum WorkflowAction: Codable, Sendable {
    case addTag(String)
    case webhook(String)
    case notify(String)
    case exportToFolder(String)
}

/// Workflow event data (passed to engine on note creation).
public struct WorkflowEvent: Sendable {
    public let title: String
    public let summary: String
    public let category: String
    public let appName: String
    public let tags: [String]
    public let confidence: Double

    public init(title: String, summary: String, category: String, appName: String, tags: [String], confidence: Double) {
        self.title = title
        self.summary = summary
        self.category = category
        self.appName = appName
        self.tags = tags
        self.confidence = confidence
    }
}
