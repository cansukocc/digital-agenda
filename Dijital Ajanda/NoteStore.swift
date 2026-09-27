//
//  NoteStore.swift
//  Dijital Ajanda
//
//  Günlere ve günlük sayfalarına yazılan notların saklanması.
//

import Foundation
import Observation

/// Bir notun hangi sayfaya ait olduğunu belirtir.
enum NoteID {
    case day(Date)
    case journal(Int)
    /// Günlük sayfasının üstündeki elle yazılan tarih.
    case journalDate(Int)

    fileprivate var key: String {
        switch self {
        case .day(let date): return "day." + AgendaCalendar.key(date)
        case .journal(let number): return "journal.\(number)"
        case .journalDate(let number): return "journalDate.\(number)"
        }
    }
}

/// Yuvarlağa dokunarak işaretlenen tek bir yapılacak iş.
struct TodoItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var done = false
}

/// Bir yapılacaklar listesinin hangi sayfaya ait olduğunu belirtir.
enum TodoScope {
    case day(Date)
    /// Verilen tarihin içinde bulunduğu haftanın listesi.
    case week(Date)

    fileprivate var key: String {
        switch self {
        case .day(let date): return "day." + AgendaCalendar.key(date)
        case .week(let date): return "week." + AgendaCalendar.key(AgendaCalendar.weekStart(date))
        }
    }
}

@Observable
final class NoteStore {
    private static let prefix = "note."
    private static let todoPrefix = "todo."

    private var notes: [String: String] = [:]
    private var todoLists: [String: [TodoItem]] = [:]

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for (key, value) in defaults.dictionaryRepresentation() where key.hasPrefix(Self.prefix) {
            if let text = value as? String {
                notes[String(key.dropFirst(Self.prefix.count))] = text
            }
        }
        for (key, value) in defaults.dictionaryRepresentation() where key.hasPrefix(Self.todoPrefix) {
            if let data = value as? Data, let items = try? JSONDecoder().decode([TodoItem].self, from: data) {
                todoLists[String(key.dropFirst(Self.todoPrefix.count))] = items
            }
        }
    }

    func text(for id: NoteID) -> String {
        notes[id.key] ?? ""
    }

    func hasText(for id: NoteID) -> Bool {
        !text(for: id).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func setText(_ text: String, for id: NoteID) {
        let key = id.key
        if text.isEmpty {
            notes[key] = nil
            defaults.removeObject(forKey: Self.prefix + key)
        } else {
            notes[key] = text
            defaults.set(text, forKey: Self.prefix + key)
        }
    }

    // MARK: - Yapılacaklar

    func todos(for scope: TodoScope) -> [TodoItem] {
        todoLists[scope.key] ?? []
    }

    func setTodos(_ items: [TodoItem], for scope: TodoScope) {
        let key = scope.key
        if items.isEmpty {
            todoLists[key] = nil
            defaults.removeObject(forKey: Self.todoPrefix + key)
        } else {
            todoLists[key] = items
            if let data = try? JSONEncoder().encode(items) {
                defaults.set(data, forKey: Self.todoPrefix + key)
            }
        }
    }

    /// Bellekteki bütün notları ve yapılacakları siler (kilit sıfırlanırken kullanılır;
    /// UserDefaults temizliğini `LockManager.resetEverything()` yapar).
    func reset() {
        notes = [:]
        todoLists = [:]
    }

    /// Günde not ya da yapılacak bir şey yazılmış mı (aylık görünümdeki nokta için).
    func hasContent(on day: Date) -> Bool {
        hasText(for: .day(day)) || !todos(for: .day(day)).isEmpty
    }
}
