import SwiftUI

struct SearchSettingsView: View {
    @AppStorage("searchHybridEnabled") private var hybridEnabled = true
    @AppStorage("searchSemanticWeight") private var semanticWeight = 0.6

    var body: some View {
        Form {
            Section("Search Mode") {
                Toggle("Hybrid Search", isOn: $hybridEnabled)
                    .help("Combine semantic (AI) and keyword (FTS5) search for better results")

                if !hybridEnabled {
                    Text("Using semantic search only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if hybridEnabled {
                Section("Ranking Balance") {
                    HStack {
                        Text("Keyword")
                        Slider(value: $semanticWeight, in: 0.2...0.8, step: 0.1)
                        Text("Semantic")
                    }
                    Text("Semantic weight: \(Int(semanticWeight * 100))% — Keyword weight: \(Int((1 - semanticWeight) * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
