// Streak/Streak/UpcomingTasksView.swift

import SwiftUI

/// Open tasks for the next 7 days.
struct UpcomingTasksView: View {

    @ObservedObject var store: DataStore

    private let days = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Задачи на неделю")
                .font(.system(size: 18, weight: .bold))

            if items.isEmpty {
                Text("Нет задач на неделю")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            row(item)
                        }
                    }
                    .padding(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppPalette.cardBackground)
        .cornerRadius(12)
    }

    private var items: [UpcomingTask] {
        store.upcomingTasks(days: days)
    }

    private func row(_ item: UpcomingTask) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTask(date: item.date, taskID: item.task.id)
            } label: {
                Image(systemName: item.task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.task.isDone ? AppPalette.accent : .secondary)
            }
            .buttonStyle(.plain)

            Text(weekday(item.date))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppPalette.accent)
                .frame(width: 34, alignment: .leading)

            Text(item.task.title)
                .font(.system(size: 14))
                .lineLimit(2)

            Spacer(minLength: 0)

            if let time = item.task.reminderTime {
                Text(DateHelper.timeFormatter.string(from: time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(AppPalette.windowBackground)
        .cornerRadius(8)
    }

    private func weekday(_ date: Date) -> String {
        DateHelper.weekdayShortFormatter.string(from: date)
    }
}
