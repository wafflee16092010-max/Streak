// Streak/Streak/CalendarView.swift

import SwiftUI

/// Month grid: 7 columns (Mon–Sun), up to 6 rows.
struct CalendarView: View {

    @ObservedObject var store: DataStore
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date?

    private let weekdayTitles = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let cellHeight: CGFloat = 56

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysOfMonth()) { cell in
                    cellView(for: cell)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppPalette.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Cells

    /// Days of the month plus filler cells so that the 1st lands on the right weekday.
    private func daysOfMonth() -> [CalendarCell] {
        let calendar = DateHelper.mondayCalendar
        let monthStart = DateHelper.startOfMonth(for: currentMonth)
        guard let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count else { return [] }

        let leading = (calendar.component(.weekday, from: monthStart) + 5) % 7
        var cells: [CalendarCell] = []

        for offset in stride(from: leading, to: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -offset, to: monthStart)
            cells.append(CalendarCell(id: cells.count, date: date, kind: .otherMonth))
        }

        for day in 0..<dayCount {
            let date = calendar.date(byAdding: .day, value: day, to: monthStart)
            cells.append(CalendarCell(id: cells.count, date: date, kind: .inMonth))
        }

        while cells.count % 7 != 0 {
            let date = calendar.date(byAdding: .day, value: cells.count - leading + 1, to: monthStart)
            cells.append(CalendarCell(id: cells.count, date: date, kind: .otherMonth))
        }

        return cells
    }

    @ViewBuilder
    private func cellView(for cell: CalendarCell) -> some View {
        if let date = cell.date {
            dayButton(for: date, dimmed: cell.kind == .otherMonth)
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: cellHeight)
        }
    }

    private func dayButton(for date: Date, dimmed: Bool) -> some View {
        let entry = store.getEntry(date: date)
        let hours = entry?.hours ?? 0
        let hasEntry = hours > 0
        let tasks = entry?.tasks ?? []
        let isToday = DateHelper.isSameDay(date, Date())

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(DateHelper.mondayCalendar.component(.day, from: date))")
                    .font(.system(size: 14))
                    .foregroundColor(textColor(dimmed: dimmed, hasEntry: hasEntry, hours: hours))

                if hasEntry {
                    Text("\(DateHelper.formatHours(hours))ч")
                        .font(.caption2)
                        .foregroundColor(dimmed ? .secondary : .primary.opacity(0.85))
                }

                taskDot(for: tasks, dimmed: dimmed)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(hasEntry ? AppPalette.heatColor(for: hours) : Color.primary.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? AppPalette.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(dimmed)
    }

    /// Small dot: red while some tasks are open, green when all are done.
    @ViewBuilder
    private func taskDot(for tasks: [TaskItem], dimmed: Bool) -> some View {
        if tasks.isEmpty {
            Color.clear.frame(width: 4, height: 4)
        } else {
            Circle()
                .fill(dotColor(for: tasks, dimmed: dimmed))
                .frame(width: 4, height: 4)
        }
    }

    private func dotColor(for tasks: [TaskItem], dimmed: Bool) -> Color {
        if dimmed { return .gray.opacity(0.4) }
        return tasks.contains { !$0.isDone } ? .red : .green
    }

    private func textColor(dimmed: Bool, hasEntry: Bool, hours: Double) -> Color {
        if dimmed { return .secondary.opacity(0.4) }
        if hasEntry && hours >= 6 { return .white }
        return .primary
    }
}
