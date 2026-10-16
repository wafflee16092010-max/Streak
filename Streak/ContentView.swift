// Streak/Streak/ContentView.swift

import SwiftUI

/// Main window: month navigation, calendar, statistics and chart.
struct ContentView: View {

    @StateObject private var store = DataStore()
    @State private var currentMonth = DateHelper.startOfMonth(for: Date())
    @State private var selectedDate: Date?

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                header

                HStack(alignment: .top, spacing: 12) {
                    CalendarView(store: store,
                                 currentMonth: $currentMonth,
                                 selectedDate: $selectedDate)
                        .frame(width: leftWidth(total: proxy.size.width))

                    VStack(spacing: 12) {
                        StatsView(store: store, month: currentMonth)
                        ChartView(store: store, month: currentMonth)
                            .frame(maxHeight: .infinity)
                        UpcomingTasksView(store: store)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: rightWidth(total: proxy.size.width))
                }
            }
            .padding(16)
        }
        .frame(minWidth: 1000, minHeight: 850)
        .background(AppPalette.windowBackground)
        .preferredColorScheme(.dark)
        .sheet(item: selectionBinding) { selection in
            DayDetailView(store: store, date: selection.date)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                shiftMonth(by: -1)
            } label: {
                Text("‹").font(.system(size: 18, weight: .bold))
            }

            Text(monthTitle)
                .font(.system(size: 18, weight: .bold))
                .frame(minWidth: 170, alignment: .leading)

            Button {
                shiftMonth(by: 1)
            } label: {
                Text("›").font(.system(size: 18, weight: .bold))
            }

            Spacer()

            Button("Сегодня") {
                currentMonth = DateHelper.startOfMonth(for: Date())
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var monthTitle: String {
        DateHelper.capitalized(DateHelper.monthTitleFormatter.string(from: currentMonth))
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        let calendar = DateHelper.mondayCalendar
        guard let shifted = calendar.date(byAdding: .month, value: value, to: currentMonth) else { return }
        currentMonth = DateHelper.startOfMonth(for: shifted)
    }

    private func leftWidth(total: CGFloat) -> CGFloat {
        max(320, total * 0.7 - 32)
    }

    private func rightWidth(total: CGFloat) -> CGFloat {
        max(260, total * 0.3 - 32)
    }

    /// Bridges `Date?` state to `.sheet(item:)`.
    private var selectionBinding: Binding<DateSelection?> {
        Binding<DateSelection?>(
            get: { selectedDate.map { DateSelection(date: $0) } },
            set: { selectedDate = $0?.date }
        )
    }
}

#Preview {
    ContentView()
}
