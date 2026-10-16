// Streak/Streak/ChartView.swift

import SwiftUI
import Charts

/// Bar chart of hours per day for the selected month.
struct ChartView: View {

    @ObservedObject var store: DataStore
    let month: Date

    private var points: [ChartPoint] { store.points(in: month) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("По дням месяца")
                .font(.system(size: 18, weight: .bold))

            Chart(points) { point in
                BarMark(
                    x: .value("День", point.day),
                    y: .value("Часы", point.hours > 0 ? point.hours : 0.1)
                )
                .foregroundStyle(point.hours > 0 ? AppPalette.accent : Color.gray.opacity(0.35))
                .annotation(position: .top) {
                    if point.hours > 0 {
                        Text(DateHelper.formatHours(point.hours))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartXScale(domain: 0.5...Double(max(points.count, 1)) + 0.5)
            .chartXAxis {
                AxisMarks(values: Array(stride(from: 1, through: max(points.count, 1), by: 3))) { value in
                    AxisValueLabel(centered: true) {
                        if let day = value.as(Int.self) {
                            Text("\(day)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(minHeight: 180)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppPalette.cardBackground)
        .cornerRadius(12)
    }
}
