//
//  JournalPageView.swift
//  Dijital Ajanda
//
//  Ajandanın sonundaki boş günlük / sabah sayfaları.
//

import SwiftUI

struct JournalPageView: View {
    let number: Int

    @Environment(NoteStore.self) private var notes

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            LinedTextEditor(text: Binding(
                get: { notes.text(for: .journal(number)) },
                set: { notes.setText($0, for: .journal(number)) }
            ))
            .frame(maxHeight: .infinity)
            .accessibilityLabel("Günlük sayfası \(number) notları")
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sabah Sayfaları")
                    .font(Theme.serif(28, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Sayfa \(number) / \(AgendaCalendar.journalPageCount)")
                    .font(Theme.serif(15))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer(minLength: 8)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("Tarih")
                    .font(Theme.serif(14))
                    .foregroundStyle(Theme.inkSoft)
                Rectangle()
                    .fill(Theme.rule)
                    .frame(width: 64, height: 1)
            }
        }
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.75)).frame(height: 1.5)
        }
        .padding(.bottom, 4)
    }
}
