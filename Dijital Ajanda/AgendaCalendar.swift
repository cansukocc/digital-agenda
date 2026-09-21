//
//  AgendaCalendar.swift
//  Dijital Ajanda
//
//  Ajandanın kapsadığı tarih aralığı ve tüm tarih hesapları burada.
//

import Foundation

enum AgendaCalendar {
    /// Ajandanın ilk ve son günü (Ekim 2026 – Aralık 2027).
    static let start = date(2026, 10, 1)
    static let end = date(2027, 12, 31)

    /// Son günden sonra gelen boş günlük / sabah sayfası sayısı.
    static let journalPageCount = 30

    /// Her ayın bitiminde (ayın son gününden sonra) aylar tablosu tekrar açılsın mı?
    static let repeatsMonthsTableAtMonthEnd = true

    static let locale = Locale(identifier: "tr_TR")

    /// Haftası pazartesi başlayan Türkçe takvim.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }()

    // MARK: - Günler

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static var today: Date { calendar.startOfDay(for: .now) }

    /// Ajanda açıldığında görünen gün: bugün, bugün aralığın dışındaysa en yakın uç.
    static var home: Date { clamp(today) }

    static func clamp(_ date: Date) -> Date {
        min(max(calendar.startOfDay(for: date), start), end)
    }

    static func contains(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= start && day <= end
    }

    static func sameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    static func addDays(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    static func addMonths(_ date: Date, _ months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: date)!
    }

    static func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    static func isFirstOfMonth(_ date: Date) -> Bool {
        calendar.component(.day, from: date) == 1
    }

    static func isLastOfMonth(_ date: Date) -> Bool {
        isFirstOfMonth(addDays(date, 1))
    }

    // MARK: - Haftalar

    static func weekStart(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }

    static func weekDays(_ date: Date) -> [Date] {
        let first = weekStart(date)
        return (0..<7).map { addDays(first, $0) }
    }

    static func weekNumber(_ date: Date) -> Int {
        calendar.component(.weekOfYear, from: date)
    }

    // MARK: - Aylar

    static func monthStart(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)!.start
    }

    /// Ajandanın kapsadığı ayların ilk günleri.
    static var months: [Date] {
        var result: [Date] = []
        var month = monthStart(start)
        while month <= end {
            result.append(month)
            month = addMonths(month, 1)
        }
        return result
    }

    /// Ayı gösteren takvim ızgarası: her satır pazartesiden pazara bir hafta.
    static func monthWeeks(_ date: Date) -> [[Date]] {
        let first = monthStart(date)
        let nextMonth = addMonths(first, 1)
        var weeks: [[Date]] = []
        var week = weekStart(first)
        while week < nextMonth {
            weeks.append(weekDays(week))
            week = addDays(week, 7)
        }
        return weeks
    }

    // MARK: - Anahtarlar

    /// Notların saklanmasında kullanılan "2026-10-01" biçimli anahtar.
    static func key(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}

/// Türkçe tarih biçimleri.
enum AgendaFormat {
    private static func formatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = AgendaCalendar.calendar
        formatter.locale = AgendaCalendar.locale
        formatter.dateFormat = pattern
        return formatter
    }

    private static let dayNumber = formatter("d")
    private static let weekday = formatter("EEEE")
    private static let weekdayShort = formatter("EEE")
    private static let monthName = formatter("LLLL")
    private static let monthYear = formatter("LLLL yyyy")
    private static let year = formatter("yyyy")

    static func day(_ date: Date) -> String { dayNumber.string(from: date) }
    static func weekdayName(_ date: Date) -> String { weekday.string(from: date) }
    static func weekdayShortName(_ date: Date) -> String { weekdayShort.string(from: date) }
    static func month(_ date: Date) -> String { monthName.string(from: date) }
    static func monthAndYear(_ date: Date) -> String { monthYear.string(from: date) }
    static func yearNumber(_ date: Date) -> String { year.string(from: date) }

    /// "19 – 25 Ekim 2026", "28 Eylül – 4 Ekim 2026" ya da yıl geçişinde iki yılı da içeren aralık.
    static func weekRange(_ date: Date) -> String {
        let days = AgendaCalendar.weekDays(date)
        let first = days[0], last = days[6]
        if yearNumber(first) != yearNumber(last) {
            return "\(day(first)) \(month(first)) \(yearNumber(first)) – \(day(last)) \(month(last)) \(yearNumber(last))"
        }
        if month(first) != month(last) {
            return "\(day(first)) \(month(first)) – \(day(last)) \(month(last)) \(yearNumber(last))"
        }
        return "\(day(first)) – \(day(last)) \(month(last)) \(yearNumber(last))"
    }
}
