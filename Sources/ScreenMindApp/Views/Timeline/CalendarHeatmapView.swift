import SwiftUI
import SwiftData
import StorageCore

/// Calendar heatmap showing note activity per day.
struct CalendarHeatmapView: View {
    @Query(sort: \NoteModel.createdAt, order: .reverse) private var allNotes: [NoteModel]
    @Binding var selectedDate: Date?
    @State private var displayMonth: Date = .now

    private let calendar = Calendar.current
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 8) {
            // Month navigation
            HStack {
                Button {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)

                Text(displayMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)

                Button {
                    displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Day headers
            HStack(spacing: 2) {
                ForEach(dayNames, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                // Offset for first day
                ForEach(0..<firstWeekdayOffset(), id: \.self) { _ in
                    Color.clear.frame(height: 28)
                }

                ForEach(days, id: \.self) { date in
                    let count = noteCount(for: date)
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let isToday = calendar.isDateInToday(date)

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 10, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? .primary : (count > 0 ? .primary : .tertiary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(heatmapColor(count: count))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                ForEach([0, 3, 8, 15, 25], id: \.self) { count in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(count: count))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date] {
        let range = calendar.range(of: .day, in: .month, for: displayMonth)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func firstWeekdayOffset() -> Int {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        return calendar.component(.weekday, from: startOfMonth) - 1
    }

    private func noteCount(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return allNotes.filter { $0.createdAt >= startOfDay && $0.createdAt < endOfDay }.count
    }

    private func heatmapColor(count: Int) -> Color {
        if count == 0 { return .clear }
        let intensity = min(Double(count) / 20.0, 1.0)
        return Color.accentColor.opacity(0.15 + intensity * 0.6)
    }
}
