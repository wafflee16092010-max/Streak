// Streak/Streak/Models.swift

import Foundation
import SwiftUI

/// A single study day: hours, note and tasks.
struct DayEntry: Codable, Equatable {
    var hours: Double = 0
    var note: String = ""
    var tasks: [TaskItem] = []
}

/// A study task inside a day.
struct TaskItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var reminderTime: Date? = nil
}

/// A cell of the month grid: a real day (possibly from a neighbour month) or a blank filler.
struct CalendarCell: Identifiable {
    enum Kind {
        case inMonth
        case otherMonth
        case empty
    }

    let id: Int
    let date: Date?
    let kind: Kind
}

/// Wrapper that makes an optional selected date usable with `.sheet(item:)`.
struct DateSelection: Identifiable {
    let date: Date
    var id: Date { date }
}

/// A task together with the day it belongs to.
struct UpcomingTask: Identifiable {
    let date: Date
    let task: TaskItem
    var id: UUID { task.id }
}

/// One bar of the monthly chart.
struct ChartPoint: Identifiable {
    let day: Int
    let hours: Double
    var id: Int { day }
}

/// Shared date helpers.
enum DateHelper {

    static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let weekdayShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// Calendar used by the grid: weeks start on Monday.
    static var mondayCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    static func key(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func date(fromKey key: String) -> Date? {
        keyFormatter.date(from: key)
    }

    static func startOfDay(_ date: Date) -> Date {
        mondayCalendar.startOfDay(for: date)
    }

    static func startOfMonth(for date: Date) -> Date {
        let components = mondayCalendar.dateComponents([.year, .month], from: date)
        return mondayCalendar.date(from: components) ?? startOfDay(date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        mondayCalendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        mondayCalendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }

    /// "3.5" / "4" — drops the fractional part when it is zero.
    static func formatHours(_ hours: Double) -> String {
        let rounded = (hours * 10).rounded() / 10
        if abs(rounded - rounded.rounded()) < 0.05 {
            return String(Int(rounded.rounded()))
        }
        return String(format: "%.1f", rounded)
    }
}

/// Palette used across the app.
enum AppPalette {
    static let accent = Color(red: 0.31, green: 0.76, blue: 0.97)
    static let windowBackground = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.14)

    /// Background for a day with an entry, depending on hours studied.
    static func heatColor(for hours: Double) -> Color {
        switch hours {
        case ..<1.6: return Color(red: 0.10, green: 0.30, blue: 0.10)
        case ..<3.6: return Color(red: 0.16, green: 0.45, blue: 0.16)
        case ..<5.6: return Color(red: 0.23, green: 0.60, blue: 0.23)
        default: return Color(red: 0.30, green: 0.75, blue: 0.30)
        }
    }
}
