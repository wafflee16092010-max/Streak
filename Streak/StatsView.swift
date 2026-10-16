// Streak/Streak/StatsView.swift

import SwiftUI

/// Four summary rows for the selected month.
struct StatsView: View {

    @ObservedObject var store: DataStore
    let month: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика")
                .font(.system(size: 18, weight: .bold))

            row(symbol: "flame.fill",
                color: .orange,
                text: "Streak: \(store.streak()) \(pluralDays(store.streak()))")

            row(symbol: "book.fill",
                color: AppPalette.accent,
                text: "Всего: \(DateHelper.formatHours(store.totalHours(in: month))) ч")

            row(symbol: "chart.line.uptrend.xyaxis",
                color: .green,
                text: "Среднее: \(DateHelper.formatHours(store.averageHours(in: month))) ч/день")

            row(symbol: "star.fill",
                color: .yellow,
                text: bestDayText)

            row(symbol: "checkmark.circle.fill",
                color: .green,
                text: tasksText)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.cardBackground)
        .cornerRadius(12)
    }

    private var tasksText: String {
        let tasks = store.tasksCompleted(in: month)
        return "Задачи: \(tasks.done) / \(tasks.total)"
    }

    private var bestDayText: String {
        guard let best = store.bestDay(in: month) else { return "Лучший день: —" }
        let day = DateHelper.shortDateFormatter.string(from: best.0)
        return "Лучший день: \(day) (\(DateHelper.formatHours(best.1))ч)"
    }

    private func row(symbol: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
            Spacer(minLength: 0)
        }
    }

    private func pluralDays(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня" }
        return "дней"
    }
}
