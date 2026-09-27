//
//  JournalPageView.swift
//  Dijital Ajanda
//
//  Ajandanın sonundaki boş günlük / sabah sayfaları: yazılabilir "Tarih" satırı ve çizgili yazı alanı.
//

import SwiftUI

struct JournalPageView: View {
    let number: Int

    @Environment(NoteStore.self) private var notes

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dateLine
            LinedTextEditor(text: Binding(
                get: { notes.text(for: .journal(number)) },
                set: { notes.setText($0, for: .journal(number)) }
            ))
            .frame(maxHeight: .infinity)
            .accessibilityLabel("Günlük sayfası \(number) / \(AgendaCalendar.journalPageCount)")
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var dateBinding: Binding<String> {
        Binding(
            get: { notes.text(for: .journalDate(number)) },
            set: { notes.setText($0, for: .journalDate(number)) }
        )
    }

    private var dateLine: some View {
        HStack(alignment: .lastTextBaseline, spacing: 10) {
            Text("Tarih")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.inkSoft)

            VStack(spacing: 2) {
                TextField(
                    "",
                    text: dateBinding,
                    prompt: Text("gün ay yıl").foregroundStyle(Theme.inkSoft.opacity(0.5))
                )
                .font(Theme.serif(18))
                .foregroundStyle(Theme.ink)
                .tint(Theme.accent)
                .submitLabel(.done)
                .accessibilityLabel("Sayfa tarihi")
                Rectangle()
                    .fill(Theme.rule)
                    .frame(height: 1)
            }
            .frame(maxWidth: 220)

            Button {
                dateBinding.wrappedValue = AgendaFormat.fullDay(AgendaCalendar.today)
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bugünün tarihini yaz")

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.75)).frame(height: 1.5)
        }
        .padding(.bottom, 4)
    }
}
