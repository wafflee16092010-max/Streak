// Streak/Streak/DataStore.swift

import Foundation
import Combine

/// Stores all study entries as JSON in Application Support.
final class DataStore: ObservableObject {

    /// Key is a day in "yyyy-MM-dd" format.
    @Published var entries: [String: DayEntry] = [:]

    private let calendar = DateHelper.mondayCalendar

    private var fileURL: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return nil }
        return base
            .appendingPathComponent("Streak", isDirectory: true)
            .appendingPathComponent("data.json")
    }

    init() {
        load()
    }

    // MARK: - Persistence

    func load() {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return }
        guard let decoded = try? JSONDecoder().decode([String: DayEntry].self, from: data) else { return }
        entries = decoded
    }

    func save() {
        guard let url = fileURL else { return }
        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Entries

    func getEntry(date: Date) -> DayEntry? {
        entries[DateHelper.key(for: date)]
    }

    func setEntry(date: Date, hours: Double, note: String) {
        mutate(date) { entry in
            entry.hours = min(max(hours, 0), 24)
            entry.note = note
        }
    }

    func removeEntry(date: Date) {
        guard let entry = entries[DateHelper.key(for: date)] else { return }
        for task in entry.tasks {
            NotificationManager.shared.cancelReminder(taskID: task.id)
        }
        entries.removeValue(forKey: DateHelper.key(for: date))
        save()
    }

    // MARK: - Tasks

    func addTask(to date: Date, task: TaskItem) {
        mutate(date) { entry in
            entry.tasks.append(task)
        }
        if task.reminderTime != nil {
            NotificationManager.shared.scheduleTaskReminder(task: task, on: date)
        }
    }

    /// Marking a task as done does not touch the reminder — it either fired already or is not needed.
    func toggleTask(date: Date, taskID: UUID) {
        mutate(date) { entry in
            guard let index = entry.tasks.firstIndex(where: { $0.id == taskID }) else { return }
            entry.tasks[index].isDone.toggle()
        }
    }

    func removeTask(date: Date, taskID: UUID) {
        mutate(date) { entry in
            entry.tasks.removeAll { $0.id == taskID }
        }
        NotificationManager.shared.cancelReminder(taskID: taskID)
    }

    // MARK: - Statistics

    /// Consecutive days with entries, counting back from today.
    /// An empty today does not break the streak.
    func streak() -> Int {
        let today = DateHelper.startOfDay(Date())
        var cursor: Date? = hasRecord(on: today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)

        var count = 0
        while let day = cursor, hasRecord(on: day) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: day)
        }
        return count
    }

    func totalHours(in month: Date) -> Double {
        daysOf(month).reduce(0) { partial, day in
            partial + (getEntry(date: day)?.hours ?? 0)
        }
    }

    /// Average hours per studied day within the month.
    func averageHours(in month: Date) -> Double {
        let values = daysOf(month).compactMap { getEntry(date: $0)?.hours }.filter { $0 > 0 }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    func bestDay(in month: Date) -> (Date, Double)? {
        var best: (Date, Double)?
        for day in daysOf(month) {
            guard let hours = getEntry(date: day)?.hours, hours > 0 else { continue }
            if best == nil || hours > best?.1 ?? -1 {
                best = (day, hours)
            }
        }
        return best
    }

    /// Tasks done / total for the month.
    func tasksCompleted(in month: Date) -> (done: Int, total: Int) {
        var done = 0
        var total = 0
        for day in daysOf(month) {
            guard let tasks = getEntry(date: day)?.tasks else { continue }
            total += tasks.count
            done += tasks.filter { $0.isDone }.count
        }
        return (done, total)
    }

    /// Bars for the chart: every day of the month, 0 for days without an entry.
    func points(in month: Date) -> [ChartPoint] {
        daysOf(month).enumerated().map { index, day in
            ChartPoint(day: index + 1, hours: getEntry(date: day)?.hours ?? 0)
        }
    }

    /// Tasks scheduled for the next `days` days, ordered by day.
    func upcomingTasks(days: Int) -> [UpcomingTask] {
        let calendar = DateHelper.mondayCalendar
        let today = DateHelper.startOfDay(Date())
        var result: [UpcomingTask] = []

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            guard let tasks = getEntry(date: day)?.tasks else { continue }
            for task in tasks where !task.isDone {
                result.append(UpcomingTask(date: day, task: task))
            }
        }

        return result.sorted { lhs, rhs in
            let left = lhs.task.reminderTime ?? lhs.date
            let right = rhs.task.reminderTime ?? rhs.date
            return left < right
        }
    }

    // MARK: - Helpers

    private func hasRecord(on day: Date) -> Bool {
        guard let entry = getEntry(date: day) else { return false }
        return entry.hours > 0 || !entry.tasks.isEmpty
    }

    /// Applies a change and drops the day when it became empty.
    private func mutate(_ date: Date, _ change: (inout DayEntry) -> Void) {
        let key = DateHelper.key(for: date)
        var entry = entries[key] ?? DayEntry()
        change(&entry)

        if entry.hours <= 0 && entry.note.isEmpty && entry.tasks.isEmpty {
            entries.removeValue(forKey: key)
        } else {
            entries[key] = entry
        }
        save()
    }

    private func daysOf(_ month: Date) -> [Date] {
        let monthStart = DateHelper.startOfMonth(for: month)
        guard let count = calendar.range(of: .day, in: .month, for: monthStart)?.count else { return [] }
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: monthStart) }
    }
}
