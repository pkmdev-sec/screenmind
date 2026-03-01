import SwiftUI

/// Visual confidence indicator — a small gauge showing AI confidence level.
struct ConfidenceIndicator: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)
            Text("\(Int(confidence * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }
}
