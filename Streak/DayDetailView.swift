// Streak/Streak/DayDetailView.swift

import SwiftUI

/// Modal sheet with the study record and the task list of a single day.
struct DayDetailView: View {

    @ObservedObject var store: DataStore
    let date: Date

    @Environment(\.dismiss) private var dismiss

    @State private var hours: Double
    @State private var note: String

    @State private var newTitle: String = ""
    @State private var hasReminder: Bool = false
    @State private var reminderTime: Date

    private let existingEntry: DayEntry?

    init(store: DataStore, date: Date) {
        self.store = store
        self.date = date
        let entry = store.getEntry(date: date)
        existingEntry = entry
        _hours = State(initialValue: entry?.hours ?? 0)
        _note = State(initialValue: entry?.note ?? "")
        _reminderTime = State(initialValue: DateHelper.mondayCalendar.date(byAdding: .hour,
                                                                            value: 18,
                                                                            to: DateHelper.startOfDay(date)) ?? Date())
    }

    private var hasStoredRecord: Bool {
        store.getEntry(date: date) != nil
    }

    private var tasks: [TaskItem] {
        store.getEntry(date: date)?.tasks ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))

            studySection

            Divider()

            tasksSection

            Divider()

            HStack(spacing: 12) {
                Button("Сохранить") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(AppPalette.accent)

                if hasStoredRecord {
                    Button("Удалить запись") { deleteEntry() }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }

                Spacer()

                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 420)
        .background(AppPalette.cardBackground)
        .preferredColorScheme(.dark)
    }

    // MARK: - Study

    private var studySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Учёба")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Stepper(value: $hours, in: 0...24, step: 0.5) {
                HStack(spacing: 12) {
                    Text("Часов:")
                        .font(.system(size: 14))
                    Spacer()
                    Text(DateHelper.formatHours(hours))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppPalette.accent)
                        .monospacedDigit()
                }
            }

            Text("Заметка о дне")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            TextEditor(text: $note)
                .font(.system(size: 14))
                .frame(height: 100)
                .padding(8)
                .background(AppPalette.windowBackground)
                .cornerRadius(8)
        }
    }

    // MARK: - Tasks

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Задачи на день")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if !tasks.isEmpty {
                    Text("\(tasks.filter { $0.isDone }.count) / \(tasks.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            if tasks.isEmpty {
                Text("Задач пока нет")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(tasks) { task in
                            taskRow(task)
                        }
                    }
                    .padding(2)
                }
                .frame(maxHeight: 160)
            }

            addTaskRow
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTask(date: date, taskID: task.id)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isDone ? AppPalette.accent : .secondary)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 14))
                .strikethrough(task.isDone)
                .foregroundColor(task.isDone ? .secondary : .primary)

            if let time = task.reminderTime {
                Text(DateHelper.timeFormatter.string(from: time))
                    .font(.caption2)
                    .foregroundColor(AppPalette.accent)
            }

            Spacer(minLength: 0)

            Button {
                store.removeTask(date: date, taskID: task.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(AppPalette.windowBackground)
        .cornerRadius(8)
    }

    private var addTaskRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Новая задача", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addTask() }

                Button("Добавить задачу") { addTask() }
                    .buttonStyle(.bordered)
                    .disabled(trimmedTitle.isEmpty)
            }

            Toggle("Напомнить в", isOn: $hasReminder)
                .font(.system(size: 12))
                .onChange(of: hasReminder) { _, enabled in
                    if enabled { reminderTime = defaultReminderTime }
                }

            if hasReminder {
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.field)
            }
        }
    }

    // MARK: - Actions

    private var title: String {
        DateHelper.capitalized(DateHelper.fullDateFormatter.string(from: date))
    }

    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var defaultReminderTime: Date {
        let dayStart = DateHelper.startOfDay(date)
        return DateHelper.mondayCalendar.date(byAdding: .hour, value: 18, to: dayStart) ?? Date()
    }

    private func addTask() {
        guard !trimmedTitle.isEmpty else { return }
        let task = TaskItem(title: trimmedTitle,
                            reminderTime: hasReminder ? reminderTime : nil)
        store.addTask(to: date, task: task)
        newTitle = ""
    }

    private func save() {
        store.setEntry(date: date, hours: hours, note: note)
        dismiss()
    }

    private func deleteEntry() {
        store.removeEntry(date: date)
        dismiss()
    }
}
