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

    fileprivate var key: String {
        switch self {
        case .day(let date): return "day." + AgendaCalendar.key(date)
        case .journal(let number): return "journal.\(number)"
        }
    }
}

@Observable
final class NoteStore {
    private static let prefix = "note."

    private var notes: [String: String] = [:]

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for (key, value) in defaults.dictionaryRepresentation() where key.hasPrefix(Self.prefix) {
            if let text = value as? String {
                notes[String(key.dropFirst(Self.prefix.count))] = text
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
}
