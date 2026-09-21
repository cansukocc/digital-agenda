//
//  AgendaPage.swift
//  Dijital Ajanda
//
//  Ajandanın sayfaları ve aralarındaki sıra (önceki / sonraki).
//

import Foundation

enum AgendaPage: Hashable {
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
        case .months(let month):
            if Cal.sameDay(month, Cal.monthStart(Cal.start)) { return nil }
            return .day(Cal.addDays(month, -1))

        case .day(let day):
            if Cal.isFirstOfMonth(day), Cal.repeatsMonthsTableAtMonthEnd || Cal.sameDay(day, Cal.start) {
                return .months(day)
            }
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

    // MARK: - Görünüm değiştirme (kenardaki düğme): gün → hafta → ay → gün

    var cycled: AgendaPage {
        typealias Cal = AgendaCalendar
        switch self {
        case .day(let day): return .week(day)
        case .week(let day): return .month(day)
        case .month(let day): return .day(Cal.clamp(day))
        case .months(let month): return .week(Cal.clamp(month))
        case .journal: return .week(Cal.home)
        }
    }

    /// Kenardaki düğmenin gösterdiği ad ve simge (basınca gidilecek görünüm).
    var viewName: String {
        switch self {
        case .day: return "Gün"
        case .week: return "Hafta"
        case .month: return "Ay"
        case .months: return "Aylar"
        case .journal: return "Günlük"
        }
    }

    var viewIcon: String {
        switch self {
        case .day: return "doc.text"
        case .week: return "list.bullet.rectangle"
        case .month: return "calendar"
        case .months: return "tablecells"
        case .journal: return "book"
        }
    }

    // MARK: - Üst çubuk başlığı

    var title: String {
        switch self {
        case .months: return "Aylar"
        case .day(let day): return AgendaFormat.monthAndYear(day)
        case .week(let day): return AgendaFormat.weekRange(day)
        case .month(let day): return AgendaFormat.yearNumber(day)
        case .journal: return "Günlük Sayfaları"
        }
    }

    /// Aylar tablosunun açılacağı ay: bakılan sayfanın ayı.
    var monthAnchor: Date {
        typealias Cal = AgendaCalendar
        switch self {
        case .months(let day), .day(let day), .week(let day), .month(let day):
            return Cal.monthStart(Cal.clamp(day))
        case .journal:
            return Cal.monthStart(Cal.home)
        }
    }

    var isMonthsTable: Bool {
        if case .months = self { return true }
        return false
    }

    var isJournal: Bool {
        if case .journal = self { return true }
        return false
    }
}
