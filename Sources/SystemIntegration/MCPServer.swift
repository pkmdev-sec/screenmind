import Foundation
import Network
import Shared

/// MCP (Model Context Protocol) server for Claude Desktop / Cursor integration.
/// Exposes ScreenMind notes as tools that AI assistants can query.
public actor MCPServer {
    public static let shared = MCPServer()

    private var listener: NWListener?
    private var isRunning = false
    private let port: UInt16 = 9877

    /// Handler for MCP tool calls (injected by AppState).
    private var toolHandler: (@Sendable (String, [String: Any]) async -> [String: Any])?

    private init() {}

    public func setToolHandler(_ handler: @escaping @Sendable (String, [String: Any]) async -> [String: Any]) {
        self.toolHandler = handler
    }

    /// Start the MCP server.
    public func start() throws {
        guard !isRunning else { return }

        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port)!)

        let listener = try NWListener(using: params)

        listener.stateUpdateHandler = { state in
            if case .ready = state {
                SMLogger.system.info("MCP server listening on http://127.0.0.1:\(self.port)")
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            Task { await self.handleConnection(connection) }
        }

        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
        self.isRunning = true
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    public var running: Bool { isRunning }

    // MARK: - MCP Protocol

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self, let data, error == nil else {
                connection.cancel()
                return
            }
            Task {
                let response = await self.processJSONRPC(data)
                let responseData = (try? JSONSerialization.data(withJSONObject: response)) ?? Data()
                let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(responseData.count)\r\nConnection: close\r\n\r\n"
                var fullResponse = httpResponse.data(using: .utf8)!
                fullResponse.append(responseData)
                connection.send(content: fullResponse, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func processJSONRPC(_ data: Data) async -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ["jsonrpc": "2.0", "error": ["code": -32700, "message": "Parse error"], "id": NSNull()]
        }

        // Extract from HTTP body (skip HTTP headers)
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        let jsonBody: [String: Any]
        if let bodyStart = bodyString.range(of: "\r\n\r\n") {
            let body = String(bodyString[bodyStart.upperBound...])
            jsonBody = (try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any]) ?? json
        } else {
            jsonBody = json
        }

        let method = jsonBody["method"] as? String ?? ""
        let id = jsonBody["id"] ?? NSNull()
        let params = jsonBody["params"] as? [String: Any] ?? [:]

        switch method {
        case "tools/list":
            return [
                "jsonrpc": "2.0",
                "result": [
                    ["name": "search_notes", "description": "Search ScreenMind notes by text or semantic query",
                     "parameters": ["type": "object", "properties": ["query": ["type": "string"], "limit": ["type": "integer"]]]],
                    ["name": "get_recent_notes", "description": "Get most recent notes",
                     "parameters": ["type": "object", "properties": ["limit": ["type": "integer"]]]],
                    ["name": "get_today_summary", "description": "Get summary of today's captured notes",
                     "parameters": ["type": "object", "properties": [:]]],
                    ["name": "get_stats", "description": "Get ScreenMind pipeline and resource stats",
                     "parameters": ["type": "object", "properties": [:]]]
                ],
                "id": id
            ]

        case "tools/call":
            let toolName = params["name"] as? String ?? ""
            let toolArgs = params["arguments"] as? [String: Any] ?? [:]

            if let handler = toolHandler {
                let result = await handler(toolName, toolArgs)
                return ["jsonrpc": "2.0", "result": result, "id": id]
            } else {
                return ["jsonrpc": "2.0", "error": ["code": -32603, "message": "No tool handler configured"], "id": id]
            }

        case "initialize":
            return [
                "jsonrpc": "2.0",
                "result": [
                    "protocolVersion": "2024-11-05",
                    "capabilities": ["tools": [:]],
                    "serverInfo": ["name": "screenmind-mcp", "version": "1.0.0"]
                ],
                "id": id
            ]

        default:
            return ["jsonrpc": "2.0", "error": ["code": -32601, "message": "Method not found: \(method)"], "id": id]
        }
    }
}
