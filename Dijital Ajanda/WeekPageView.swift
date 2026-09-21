//
//  WeekPageView.swift
//  Dijital Ajanda
//
//  Klasik haftalık ajanda görünümü: hafta günlere bölünmüş.
//  Geniş ekranda (iPad) iki sayfalık açık ajanda, dar ekranda (iPhone) alt alta yedi gün.
//

import SwiftUI

struct WeekPageView: View {
    let date: Date
    let open: (Date) -> Void

    var body: some View {
        let days = AgendaCalendar.weekDays(date)

        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                if proxy.size.width >= 560 {
                    spread(days)
                } else {
                    list(days)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Hafta \(AgendaCalendar.weekNumber(date))")
                .font(Theme.serif(26, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.ink.opacity(0.75)).frame(height: 1.5)
        }
    }

    /// İki sayfalık açık ajanda: solda Pzt-Sal-Çar, sağda Per-Cum ve Cmt|Paz.
    private func spread(_ days: [Date]) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                cell(days[0])
                cell(days[1])
                cell(days[2])
            }
            Rectangle().fill(Theme.rule).frame(width: 1)
            VStack(spacing: 0) {
                cell(days[3])
                cell(days[4])
                HStack(spacing: 0) {
                    cell(days[5])
                    Rectangle().fill(Theme.rule).frame(width: 1)
                    cell(days[6])
                }
            }
        }
    }

    private func list(_ days: [Date]) -> some View {
        VStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                cell(day, compact: true)
            }
        }
    }

    private func cell(_ day: Date, compact: Bool = false) -> some View {
        WeekDayCell(date: day, compact: compact, open: open)
    }
}

private struct WeekDayCell: View {
    let date: Date
    let compact: Bool
    let open: (Date) -> Void

    @Environment(NoteStore.self) private var notes

    private var inRange: Bool { AgendaCalendar.contains(date) }
    private var isToday: Bool { AgendaCalendar.sameDay(date, AgendaCalendar.today) }
    private var preview: String {
        notes.text(for: .day(date)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button {
            open(date)
        } label: {
            Group {
                if compact {
                    HStack(alignment: .top, spacing: 12) {
                        label
                            .frame(width: 116, alignment: .leading)
                        previewText
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        label
                        previewText
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!inRange)
        .opacity(inRange ? 1 : 0.3)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
        .accessibilityLabel("\(AgendaFormat.weekdayName(date)) \(AgendaFormat.day(date)) \(AgendaFormat.month(date))")
    }

    private var label: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(AgendaFormat.day(date))
                .font(Theme.serif(compact ? 26 : 30, weight: .light))
                .foregroundStyle(isToday ? Theme.paper : (AgendaCalendar.isWeekend(date) ? Theme.accent : Theme.ink))
                .padding(.horizontal, isToday ? 7 : 0)
                .background {
                    if isToday { Capsule().fill(Theme.accent) }
                }
            Text(AgendaFormat.weekdayName(date))
                .font(Theme.serif(14, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder
    private var previewText: some View {
        if !preview.isEmpty {
            Text(preview)
                .font(Theme.serif(14))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .lineLimit(compact ? 2 : 4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if compact {
            Spacer(minLength: 0)
        }
    }
}
