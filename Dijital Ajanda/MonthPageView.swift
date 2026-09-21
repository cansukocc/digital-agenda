//
//  MonthPageView.swift
//  Dijital Ajanda
//
//  Aylık görünüm: ayın takvim ızgarası. Güne dokununca o günün sayfası, hafta numarasına
//  dokununca o haftanın sayfası açılır.
//

import SwiftUI

struct MonthPageView: View {
    let date: Date
    let openDay: (Date) -> Void
    let openWeek: (Date) -> Void

    private static let weekColumnWidth: CGFloat = 30

    var body: some View {
        let monthStart = AgendaCalendar.monthStart(date)
        let weeks = AgendaCalendar.monthWeeks(date)

        VStack(spacing: 0) {
            header(monthStart)
            weekdayRow(weeks[0])
            VStack(spacing: 0) {
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        weekNumber(week[0])
                        ForEach(week, id: \.self) { day in
                            MonthDayCell(
                                date: day,
                                isInMonth: AgendaCalendar.monthStart(day) == monthStart,
                                open: openDay
                            )
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }

    private func header(_ monthStart: Date) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(AgendaFormat.month(monthStart))
                .font(Theme.serif(34, weight: .medium))
                .foregroundStyle(Theme.ink)
            Text(AgendaFormat.yearNumber(monthStart))
                .font(Theme.serif(20, weight: .light))
                .foregroundStyle(Theme.accent)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func weekdayRow(_ week: [Date]) -> some View {
        HStack(spacing: 0) {
            Text("H")
                .frame(width: Self.weekColumnWidth)
            ForEach(week, id: \.self) { day in
                Text(AgendaFormat.weekdayShortName(day))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(AgendaCalendar.isWeekend(day) ? Theme.accent : Theme.inkSoft)
            }
        }
        .font(Theme.serif(12, weight: .medium))
        .foregroundStyle(Theme.inkSoft)
        .padding(.vertical, 6)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.ink.opacity(0.75)).frame(height: 1.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private func weekNumber(_ firstDay: Date) -> some View {
        let days = AgendaCalendar.weekDays(firstDay)
        let inRange = days.contains { AgendaCalendar.contains($0) }
        return Button {
            openWeek(AgendaCalendar.clamp(firstDay))
        } label: {
            Text("\(AgendaCalendar.weekNumber(firstDay))")
                .font(Theme.serif(11))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 14)
                .frame(width: Self.weekColumnWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!inRange)
        .opacity(inRange ? 1 : 0.3)
        .accessibilityLabel("Hafta \(AgendaCalendar.weekNumber(firstDay))")
    }
}

private struct MonthDayCell: View {
    let date: Date
    let isInMonth: Bool
    let open: (Date) -> Void

    @Environment(NoteStore.self) private var notes

    private var inRange: Bool { AgendaCalendar.contains(date) }
    private var isToday: Bool { AgendaCalendar.sameDay(date, AgendaCalendar.today) }

    var body: some View {
        Button {
            open(date)
        } label: {
            VStack(spacing: 4) {
                Text(AgendaFormat.day(date))
                    .font(Theme.serif(17, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(numberColor)
                    .frame(minWidth: 28, minHeight: 28)
                    .background {
                        if isToday { Circle().fill(Theme.accent) }
                    }
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 5, height: 5)
                    .opacity(notes.hasText(for: .day(date)) ? 1 : 0)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!inRange)
        .opacity(inRange ? (isInMonth ? 1 : 0.35) : 0.15)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
        .accessibilityLabel("\(AgendaFormat.day(date)) \(AgendaFormat.month(date))")
    }

    private var numberColor: Color {
        if isToday { return Theme.paper }
        return AgendaCalendar.isWeekend(date) ? Theme.accent : Theme.ink
    }
}
