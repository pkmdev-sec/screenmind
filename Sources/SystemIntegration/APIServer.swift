import Foundation
import Network
import Shared

/// Lightweight local REST API server for ScreenMind.
/// Allows Alfred, Raycast, Shortcuts, and scripts to query notes.
/// Binds to localhost only (127.0.0.1) for security.
public actor APIServer {
    public static let shared = APIServer()

    private var listener: NWListener?
    private var isRunning = false
    private let port: UInt16

    /// Handler for note queries (injected by AppState).
    private var queryHandler: (@Sendable (APIRequest) async -> APIResponse)?

    /// Set the query handler (called from AppState).
    public func setQueryHandler(_ handler: @escaping @Sendable (APIRequest) async -> APIResponse) {
        self.queryHandler = handler
    }

    public init(port: UInt16 = 9876) {
        self.port = port
    }

    /// Start the API server on localhost (IPv4 + IPv6 loopback only).
    public func start() throws {
        guard !isRunning else { return }

        // Bind to IPv4 loopback (127.0.0.1) only — prevents network access
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port)!)

        let listener = try NWListener(using: params)

        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                SMLogger.system.info("API server listening on http://127.0.0.1:\(self.port)")
            case .failed(let error):
                SMLogger.system.error("API server failed: \(error.localizedDescription)")
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            Task { await self.handleConnection(connection) }
        }

        listener.start(queue: .global(qos: .userInitiated))
        self.listener = listener
        self.isRunning = true
        SMLogger.system.info("API server started on port \(self.port)")
    }

    /// Stop the API server.
    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        SMLogger.system.info("API server stopped")
    }

    public var running: Bool { isRunning }

    // MARK: - Connection Handling

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))

        // Enforce localhost-only: reject connections from non-loopback IPs (defense in depth)
        if let endpoint = connection.currentPath?.remoteEndpoint,
           case let .hostPort(host, _) = endpoint {
            let hostStr = "\(host)"
            if hostStr != "127.0.0.1" && hostStr != "::1" && hostStr != "localhost" {
                SMLogger.system.warning("API: rejected non-loopback connection from \(hostStr)")
                connection.cancel()
                return
            }
        }

        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self, let data, error == nil else {
                connection.cancel()
                return
            }

            Task {
                let response = await self.processHTTPRequest(data)
                let httpResponse = self.buildHTTPResponse(response)
                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
            }
        }
    }

    private func processHTTPRequest(_ data: Data) async -> APIResponse {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return APIResponse(status: 400, body: ["error": "Invalid request"])
        }

        // Parse HTTP request line
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return APIResponse(status: 400, body: ["error": "Empty request"])
        }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            return APIResponse(status: 400, body: ["error": "Malformed request"])
        }

        let method = String(parts[0])
        let path = String(parts[1])

        // Extract query parameters
        let urlComponents = URLComponents(string: path)
        let queryItems = urlComponents?.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        let request = APIRequest(
            method: method,
            path: urlComponents?.path ?? path,
            params: params
        )

        // Route to handler
        guard let handler = queryHandler else {
            return APIResponse(status: 503, body: ["error": "API not configured — start monitoring first"])
        }

        return await handler(request)
    }

    private nonisolated func buildHTTPResponse(_ response: APIResponse) -> String {
        let jsonData = (try? JSONSerialization.data(withJSONObject: response.body, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return """
        HTTP/1.1 \(response.status) \(httpStatusText(response.status))\r
        Content-Type: application/json\r
        Content-Length: \(jsonData.count)\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        \(jsonString)
        """
    }

    private nonisolated func httpStatusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 503: return "Service Unavailable"
        default: return "Error"
        }
    }
}

/// API request from external clients.
public struct APIRequest: Sendable {
    public let method: String
    public let path: String
    public let params: [String: String]
}

/// API response to external clients.
public struct APIResponse: Sendable {
    public let status: Int
    public let body: [String: Any]

    public init(status: Int, body: [String: Any]) {
        self.status = status
        self.body = body
    }
}

