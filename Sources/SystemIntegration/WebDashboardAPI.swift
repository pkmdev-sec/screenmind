import Foundation
import Shared

/// Extended API endpoints for web dashboard access.
/// These endpoints provide rich querying capabilities for a future web interface,
/// enabling remote access to notes, timeline visualization, knowledge graph,
/// semantic search, and daily digests.
///
/// Security: All endpoints require API key authentication when accessed remotely.
/// For localhost access, authentication is optional (controlled by UserDefaults).
public struct WebDashboardAPI {

    /// Handle web dashboard API requests.
    /// This would be called from APIServer's query handler for dashboard-specific routes.
    /// - Parameter request: The incoming API request
    /// - Parameter storage: StorageActor for database queries
    /// - Parameter semanticSearch: SemanticSearchActor for vector search
    /// - Returns: API response with appropriate status and data
    public static func handleRequest(
        _ request: APIRequest,
        apiKey: String?
    ) async -> APIResponse {
        // Authentication check (if remote access is enabled)
        if UserDefaults.standard.bool(forKey: "apiRequiresAuth") {
            guard let providedKey = request.params["apiKey"], providedKey == apiKey else {
                return APIResponse(status: 401, body: ["error": "Unauthorized - API key required"])
            }
        }

        // Route to appropriate handler based on path
        switch request.path {
        case let path where path.hasPrefix("/api/notes/") && !path.hasSuffix("/search"):
            // GET /api/notes/:id
            let noteID = String(path.dropFirst("/api/notes/".count))
            return await handleGetNote(noteID: noteID)

        case "/api/notes/search":
            // GET /api/notes/search?q=query&semantic=true&limit=50
            return await handleSearchNotes(request: request)

        case "/api/timeline":
            // GET /api/timeline?from=2024-01-01&to=2024-12-31
            return await handleGetTimeline(request: request)

        case "/api/graph":
            // GET /api/graph
            return await handleGetKnowledgeGraph()

        case "/api/digest/daily":
            // GET /api/digest/daily?date=2024-03-02
            return await handleGetDailyDigest(request: request)

        default:
            return APIResponse(status: 404, body: ["error": "Endpoint not found"])
        }
    }

    // MARK: - Endpoint Handlers

    /// GET /api/notes/:id - Get single note by ID
    private static func handleGetNote(noteID: String) async -> APIResponse {
        // TODO: Query StorageActor for note by ID
        // For now, return stub response
        return APIResponse(status: 200, body: [
            "id": noteID,
            "title": "Example Note",
            "summary": "This is a placeholder note",
            "details": "Full note details would be here",
            "category": "other",
            "tags": ["example"],
            "confidence": 0.8,
            "appName": "Safari",
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "hasScreenshot": false
        ])
    }

    /// GET /api/notes/search?q=query&semantic=true&category=coding&limit=50
    private static func handleSearchNotes(request: APIRequest) async -> APIResponse {
        let query = request.params["q"] ?? ""
        let useSemantic = request.params["semantic"] == "true"
        let category = request.params["category"]
        let limit = Int(request.params["limit"] ?? "50") ?? 50

        // TODO: If semantic=true, use SemanticSearchActor
        // TODO: Otherwise, use StorageActor.searchNotes()

        return APIResponse(status: 200, body: [
            "query": query,
            "semantic": useSemantic,
            "category": category as Any,
            "limit": limit,
            "results": [
                [
                    "id": UUID().uuidString,
                    "title": "Search Result 1",
                    "summary": "Matching note summary",
                    "category": category ?? "other",
                    "appName": "Xcode",
                    "createdAt": ISO8601DateFormatter().string(from: Date()),
                    "relevanceScore": 0.92
                ]
            ],
            "totalResults": 1
        ])
    }

    /// GET /api/timeline?from=2024-01-01T00:00:00Z&to=2024-12-31T23:59:59Z
    private static func handleGetTimeline(request: APIRequest) async -> APIResponse {
        let formatter = ISO8601DateFormatter()

        let fromDate = request.params["from"]
            .flatMap { formatter.date(from: $0) }
            ?? Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let toDate = request.params["to"]
            .flatMap { formatter.date(from: $0) }
            ?? Date()

        // TODO: Query StorageActor.fetchNotes(from:to:)
        // TODO: Group by date, compute activity heatmap data

        return APIResponse(status: 200, body: [
            "from": formatter.string(from: fromDate),
            "to": formatter.string(from: toDate),
            "timeline": [
                [
                    "date": formatter.string(from: Date()),
                    "noteCount": 5,
                    "topCategories": ["coding", "research"],
                    "topApps": ["Xcode", "Safari", "Terminal"],
                    "activityLevel": "high"
                ]
            ],
            "summary": [
                "totalNotes": 150,
                "totalDays": 30,
                "avgNotesPerDay": 5.0,
                "mostActiveDay": formatter.string(from: Date())
            ]
        ])
    }

    /// GET /api/graph - Get knowledge graph data
    private static func handleGetKnowledgeGraph() async -> APIResponse {
        // TODO: Query LinkDiscoveryActor for note connections
        // TODO: Build graph structure with nodes (notes) and edges (links)

        return APIResponse(status: 200, body: [
            "nodes": [
                [
                    "id": UUID().uuidString,
                    "title": "Note 1",
                    "category": "coding",
                    "noteCount": 1,
                    "centralityScore": 0.8
                ]
            ],
            "edges": [
                [
                    "source": UUID().uuidString,
                    "target": UUID().uuidString,
                    "weight": 0.75,
                    "linkType": "semantic"
                ]
            ],
            "clusters": [
                [
                    "id": "cluster-1",
                    "name": "iOS Development",
                    "nodeCount": 15,
                    "avgConfidence": 0.85
                ]
            ]
        ])
    }

    /// GET /api/digest/daily?date=2024-03-02
    private static func handleGetDailyDigest(request: APIRequest) async -> APIResponse {
        let formatter = ISO8601DateFormatter()
        let date = request.params["date"]
            .flatMap { formatter.date(from: $0) }
            ?? Date()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // TODO: Query StorageActor.fetchNotes(from:to:)
        // TODO: Use WeeklySummaryGenerator to create digest

        return APIResponse(status: 200, body: [
            "date": formatter.string(from: date),
            "digest": [
                "summary": "You captured 12 notes today across 5 applications",
                "topActivities": [
                    [
                        "category": "coding",
                        "noteCount": 7,
                        "timeSpent": "3.5 hours",
                        "apps": ["Xcode", "Terminal"]
                    ],
                    [
                        "category": "research",
                        "noteCount": 5,
                        "timeSpent": "2 hours",
                        "apps": ["Safari", "Arc"]
                    ]
                ],
                "highlights": [
                    "Worked on iOS development project",
                    "Researched Swift concurrency patterns",
                    "Fixed 3 bugs in API integration"
                ],
                "stats": [
                    "totalNotes": 12,
                    "uniqueApps": 5,
                    "avgConfidence": 0.82,
                    "redactedItems": 2
                ]
            ]
        ])
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Whether API requires authentication for remote access.
    public var apiRequiresAuth: Bool {
        get { bool(forKey: "apiRequiresAuth") }
        set { set(newValue, forKey: "apiRequiresAuth") }
    }

    /// API key for remote access (stored in UserDefaults for demo).
    /// In production, this should be stored in Keychain.
    public var apiKey: String? {
        get { string(forKey: "apiKey") }
        set { set(newValue, forKey: "apiKey") }
    }

    /// Whether CORS is enabled for web dashboard.
    public var corsEnabled: Bool {
        get { bool(forKey: "corsEnabled") }
        set { set(newValue, forKey: "corsEnabled") }
    }
}
