//
//  AgendaPage.swift
//  Dijital Ajanda
//
//  Ajandanın sayfaları ve aralarındaki sıra (önceki / sonraki).
//

import Foundation

enum AgendaPage: Hashable {
    /// Ajandanın kapağı (ilk sayfa).
    case cover
    /// Yıllık bakış: bütün ayların küçük takvimleri.
    case calendar
    /// Aylar tablosu. Tarih, tablonun hemen ardından başlayacak ayı belirtir.
    case months(Date)
    case day(Date)
    /// Verilen tarihin içinde bulunduğu hafta.
    case week(Date)
    /// Verilen tarihin içinde bulunduğu ay.
    case month(Date)
    /// Sondaki boş günlük / sabah sayfaları (1'den başlar).
    case journal(Int)

    // MARK: - Sayfa sırası (üstteki sağ / sol oklar)

    var previous: AgendaPage? {
        typealias Cal = AgendaCalendar
        switch self {
        case .cover:
            return nil

        case .calendar:
            return .cover

        case .months(let month):
            if Cal.sameDay(month, Cal.monthStart(Cal.start)) { return .calendar }
            return .day(Cal.addDays(month, -1))

        case .day(let day):
            // Kitabın ilk günü: öncesinde aylar tablosu (ilk ayı gösterir) vardır.
            if Cal.sameDay(day, Cal.start) { return .months(Cal.monthStart(day)) }
            if Cal.isFirstOfMonth(day), Cal.repeatsMonthsTableAtMonthEnd { return .months(day) }
            return .day(Cal.addDays(day, -1))

        case .week(let day):
            guard Cal.weekStart(day) > Cal.start else { return nil }
            return .week(Cal.clamp(Cal.addDays(day, -7)))

        case .month(let day):
            let first = Cal.monthStart(day)
            guard first > Cal.start else { return nil }
            return .month(Cal.addMonths(first, -1))

        case .journal(let number):
            return number > 1 ? .journal(number - 1) : .day(Cal.end)
        }
    }

    var next: AgendaPage? {
        typealias Cal = AgendaCalendar
        switch self {
        case .cover:
            return .calendar

        case .calendar:
            return .months(Cal.monthStart(Cal.start))

        case .months(let month):
            return .day(Cal.clamp(month))

        case .day(let day):
            if Cal.sameDay(day, Cal.end) { return .journal(1) }
            if Cal.repeatsMonthsTableAtMonthEnd, Cal.isLastOfMonth(day) {
                return .months(Cal.addDays(day, 1))
            }
            return .day(Cal.addDays(day, 1))

        case .week(let day):
            guard Cal.addDays(Cal.weekStart(day), 7) <= Cal.end else { return nil }
            return .week(Cal.clamp(Cal.addDays(day, 7)))

        case .month(let day):
            let following = Cal.addMonths(Cal.monthStart(day), 1)
            guard following <= Cal.end else { return nil }
            return .month(following)

        case .journal(let number):
            return number < Cal.journalPageCount ? .journal(number + 1) : nil
        }
    }

    // MARK: - Kenar sekmeleri için

    /// Şu an bakılan gün. Kapak, takvim ve günlük sayfalarında bugün (aralığın dışındaysa en yakın uç).
    /// Ay ve Hafta sekmeleri bu güne göre açılır.
    var anchorDate: Date {
        typealias Cal = AgendaCalendar
        switch self {
        case .months(let day), .day(let day), .week(let day), .month(let day):
            return Cal.clamp(day)
        case .cover, .calendar, .journal:
            return Cal.home
        }
    }

    // MARK: - Üst çubuk başlığı

    var title: String {
        switch self {
        case .cover: return ""
        case .calendar: return "Takvim"
        case .months: return "Aylar"
        case .day(let day): return AgendaFormat.monthAndYear(day)
        case .week(let day): return AgendaFormat.weekRange(day)
        case .month(let day): return AgendaFormat.yearNumber(day)
        case .journal: return "Günlük Sayfaları"
        }
    }

    var isCover: Bool {
        if case .cover = self { return true }
        return false
    }

    var isCalendar: Bool {
        if case .calendar = self { return true }
        return false
    }

    var isDay: Bool {
        if case .day = self { return true }
        return false
    }

    var isWeek: Bool {
        if case .week = self { return true }
        return false
    }

    var isMonth: Bool {
        if case .month = self { return true }
        return false
    }

    var isJournal: Bool {
        if case .journal = self { return true }
        return false
    }
}
