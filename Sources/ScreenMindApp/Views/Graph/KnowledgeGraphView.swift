import SwiftUI
import SwiftData
import StorageCore
import SemanticSearch
import Shared

/// Visual knowledge graph showing connections between notes.
struct KnowledgeGraphView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var allNotes: [NoteModel]
    @State private var nodes: [GraphNode] = []
    @State private var edges: [GraphEdge] = []
    @State private var selectedNodeID: String?
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var isLoading = true
    @State private var searchText = ""

    var body: some View {
        ZStack {
            // Graph canvas
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2 + offset.width, y: size.height / 2 + offset.height)

                // Draw edges
                for edge in edges {
                    guard let fromNode = nodes.first(where: { $0.id == edge.fromID }),
                          let toNode = nodes.first(where: { $0.id == edge.toID }) else { continue }
                    let from = CGPoint(x: center.x + fromNode.x * scale, y: center.y + fromNode.y * scale)
                    let to = CGPoint(x: center.x + toNode.x * scale, y: center.y + toNode.y * scale)
                    var path = Path()
                    path.move(to: from)
                    path.addLine(to: to)
                    context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 1)
                }

                // Draw nodes
                for node in nodes {
                    let pos = CGPoint(x: center.x + node.x * scale, y: center.y + node.y * scale)
                    let isSelected = node.id == selectedNodeID
                    let isHighlighted = !searchText.isEmpty && node.title.localizedCaseInsensitiveContains(searchText)
                    let radius: CGFloat = isSelected ? 10 : (isHighlighted ? 8 : 6)
                    let opacity: Double = isHighlighted || searchText.isEmpty ? 1.0 : 0.3

                    let rect = CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(node.color.opacity(opacity)))

                    if isSelected || isHighlighted {
                        context.draw(Text(node.title.prefix(20)).font(.system(size: 9)), at: CGPoint(x: pos.x, y: pos.y - radius - 8))
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.2, min(5.0, value))
                    }
            )
            .onTapGesture { location in
                selectNodeAt(location)
            }

            // Overlay controls
            VStack {
                HStack {
                    // Search
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search graph...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .frame(width: 250)

                    Spacer()

                    // Stats
                    Text("\(nodes.count) nodes, \(edges.count) edges")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    // Zoom controls
                    HStack(spacing: 8) {
                        Button { scale = max(0.2, scale - 0.2) } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        Text("\(Int(scale * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                            .frame(width: 40)
                        Button { scale = min(5.0, scale + 0.2) } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        Button { scale = 1.0; offset = .zero } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)

                Spacer()

                // Selected note detail
                if let selectedID = selectedNodeID,
                   let note = allNotes.first(where: { $0.id.uuidString == selectedID }) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.system(size: 13, weight: .semibold))
                            Text(note.summary)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack(spacing: 8) {
                                CategoryBadge(category: note.category)
                                Text(note.appName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                Text(note.createdAt, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Button("Dismiss") { selectedNodeID = nil }
                            .controlSize(.small)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                }
            }

            if isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Building knowledge graph...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task { await buildGraph() }
    }

    // MARK: - Graph Building

    private func buildGraph() async {
        // Convert notes to graph nodes with simple force layout
        var graphNodes: [GraphNode] = []
        let categoryColors: [String: Color] = [
            "coding": .green, "research": .blue, "meeting": .purple,
            "communication": .orange, "reading": .cyan, "terminal": .gray, "other": .secondary
        ]

        for (index, note) in allNotes.prefix(200).enumerated() {
            // Arrange in a spiral for initial layout
            let angle = Double(index) * 0.5
            let radius = Double(index) * 3.0
            let x = CGFloat(cos(angle) * radius)
            let y = CGFloat(sin(angle) * radius)

            graphNodes.append(GraphNode(
                id: note.id.uuidString,
                title: note.title,
                category: note.category,
                x: x,
                y: y,
                color: categoryColors[note.category] ?? .secondary
            ))
        }

        // Load links
        let linkDiscovery = LinkDiscoveryActor(semanticSearch: SemanticSearchActor())
        var graphEdges: [GraphEdge] = []
        if let links = try? await linkDiscovery.getAllLinks() {
            for link in links {
                graphEdges.append(GraphEdge(fromID: link.fromNoteID, toID: link.toNoteID, weight: link.similarity))
            }
        }

        // Apply simple force-directed layout
        applyForceLayout(&graphNodes, edges: graphEdges, iterations: 50)

        // Capture immutable copies before concurrent context
        let finalNodes = graphNodes
        let finalEdges = graphEdges

        await MainActor.run {
            self.nodes = finalNodes
            self.edges = finalEdges
            self.isLoading = false
        }
    }

    private func applyForceLayout(_ nodes: inout [GraphNode], edges: [GraphEdge], iterations: Int) {
        let repulsion: CGFloat = 500
        let attraction: CGFloat = 0.01
        let damping: CGFloat = 0.9

        for _ in 0..<iterations {
            // Repulsion (all pairs)
            for i in 0..<nodes.count {
                for j in (i+1)..<nodes.count {
                    let dx = nodes[i].x - nodes[j].x
                    let dy = nodes[i].y - nodes[j].y
                    let dist = max(sqrt(dx * dx + dy * dy), 1)
                    let force = repulsion / (dist * dist)
                    let fx = (dx / dist) * force
                    let fy = (dy / dist) * force
                    nodes[i].x += fx * damping
                    nodes[i].y += fy * damping
                    nodes[j].x -= fx * damping
                    nodes[j].y -= fy * damping
                }
            }

            // Attraction (edges)
            for edge in edges {
                guard let iIdx = nodes.firstIndex(where: { $0.id == edge.fromID }),
                      let jIdx = nodes.firstIndex(where: { $0.id == edge.toID }) else { continue }
                let dx = nodes[jIdx].x - nodes[iIdx].x
                let dy = nodes[jIdx].y - nodes[iIdx].y
                let dist = sqrt(dx * dx + dy * dy)
                let force = dist * attraction
                nodes[iIdx].x += dx * force
                nodes[iIdx].y += dy * force
                nodes[jIdx].x -= dx * force
                nodes[jIdx].y -= dy * force
            }
        }
    }

    private func selectNodeAt(_ location: CGPoint) {
        // Find nearest node to tap location (simplified)
        selectedNodeID = nil
    }
}

struct GraphNode: Identifiable {
    let id: String
    let title: String
    let category: String
    var x: CGFloat
    var y: CGFloat
    let color: Color
}

struct GraphEdge: Identifiable {
    let id = UUID()
    let fromID: String
    let toID: String
    let weight: Float
}
