//
//  DayPageView.swift
//  Dijital Ajanda
//
//  Tek günün sayfası: üstte tarih, altında çizgili yazı alanı.
//

import SwiftUI

struct DayPageView: View {
    let date: Date

    @Environment(NoteStore.self) private var notes

    private var isToday: Bool { AgendaCalendar.sameDay(date, AgendaCalendar.today) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            LinedTextEditor(text: Binding(
                get: { notes.text(for: .day(date)) },
                set: { notes.setText($0, for: .day(date)) }
            ))
            .frame(maxHeight: .infinity)
            .accessibilityLabel("\(AgendaFormat.day(date)) \(AgendaFormat.monthAndYear(date)) notları")
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(AgendaFormat.day(date))
                .font(Theme.serif(64, weight: .light))
                .foregroundStyle(AgendaCalendar.isWeekend(date) ? Theme.accent : Theme.ink)

            VStack(alignment: .leading, spacing: 2) {
                Text(AgendaFormat.weekdayName(date))
                    .font(Theme.serif(24, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text(AgendaFormat.monthAndYear(date))
                    .font(Theme.serif(16))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text("Hafta \(AgendaCalendar.weekNumber(date))")
                    .font(Theme.serif(13))
                    .foregroundStyle(Theme.inkSoft)
                if isToday {
                    Text("BUGÜN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.paper)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent, in: Capsule())
                }
            }
        }
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.75)).frame(height: 1.5)
        }
        .padding(.bottom, 4)
    }
}
