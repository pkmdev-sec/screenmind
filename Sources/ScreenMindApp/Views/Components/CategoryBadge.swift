import SwiftUI
import AIProcessing

/// Color-coded pill badge for note categories with SF Symbol icons.
struct CategoryBadge: View {
    let category: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .semibold))
            Text(category.capitalized)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(categoryColor.opacity(0.2))
        .foregroundStyle(categoryColor)
        .clipShape(Capsule())
    }

    private var categoryColor: Color {
        switch category.lowercased() {
        case "meeting": return .purple
        case "research": return .blue
        case "coding": return .green
        case "communication": return .orange
        case "reading": return .cyan
        case "terminal": return .gray
        case "other": return .secondary
        default: return .secondary
        }
    }

    private var iconName: String {
        switch category.lowercased() {
        case "meeting": return "person.3.fill"
        case "research": return "magnifyingglass"
        case "coding": return "chevron.left.forwardslash.chevron.right"
        case "communication": return "bubble.left.and.bubble.right.fill"
        case "reading": return "book.fill"
        case "terminal": return "terminal.fill"
        case "other": return "square.grid.2x2"
        default: return "square.grid.2x2"
        }
    }
}
