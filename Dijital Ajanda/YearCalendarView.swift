//
//  YearCalendarView.swift
//  Dijital Ajanda
//
//  Yıllık bakış: ajandanın kapsadığı bütün ayların küçük takvimleri. Güne dokununca o günün sayfası,
//  ay adına dokununca o ayın takvimi açılır. Not ya da yapılacağı olan günlerin altında nokta çıkar.
//

import SwiftUI

struct YearCalendarView: View {
    let openDay: (Date) -> Void
    let openMonth: (Date) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var years: [(year: String, months: [Date])] {
        var groups: [(year: String, months: [Date])] = []
        for month in AgendaCalendar.months {
            let year = AgendaFormat.yearNumber(month)
            if groups.last?.year == year {
                groups[groups.count - 1].months.append(month)
            } else {
                groups.append((year, [month]))
            }
        }
        return groups
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: sizeClass == .regular ? 3 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Takvim")
                        .font(Theme.serif(34, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text("\(AgendaFormat.monthAndYear(AgendaCalendar.start)) – \(AgendaFormat.monthAndYear(AgendaCalendar.end))")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.bottom, 8)

                ForEach(years, id: \.year) { group in
                    Text(group.year)
                        .font(Theme.serif(22, weight: .light))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.rule).frame(height: 1)
                        }

                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(group.months, id: \.self) { month in
                            MiniMonthView(month: month, openDay: openDay, openMonth: openMonth)
                        }
                    }
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct MiniMonthView: View {
    let month: Date
    let openDay: (Date) -> Void
    let openMonth: (Date) -> Void

    @Environment(NoteStore.self) private var notes

    var body: some View {
        let weeks = AgendaCalendar.monthWeeks(month)

        VStack(alignment: .leading, spacing: 2) {
            Button {
                openMonth(month)
            } label: {
                Text(AgendaFormat.month(month))
                    .font(Theme.serif(17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 4)
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                ForEach(weeks[0], id: \.self) { day in
                    Text(String(AgendaFormat.weekdayShortName(day).prefix(1)))
                        .font(Theme.serif(10, weight: .medium))
                        .foregroundStyle(AgendaCalendar.isWeekend(day) ? Theme.accent : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { day in
                        cell(day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ day: Date) -> some View {
        if AgendaCalendar.monthStart(day) == month {
            let inRange = AgendaCalendar.contains(day)
            let isToday = AgendaCalendar.sameDay(day, AgendaCalendar.today)
            Button {
                openDay(day)
            } label: {
                Text(AgendaFormat.day(day))
                    .font(Theme.serif(12, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isToday ? Theme.paper : (AgendaCalendar.isWeekend(day) ? Theme.accent : Theme.ink))
                    .frame(width: 22, height: 22)
                    .background {
                        if isToday { Circle().fill(Theme.accent) }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 25)
                    .overlay(alignment: .bottom) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 3, height: 3)
                            .opacity(notes.hasContent(on: day) ? 1 : 0)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!inRange)
            .opacity(inRange ? 1 : 0.3)
            .accessibilityLabel("\(AgendaFormat.day(day)) \(AgendaFormat.month(day))")
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: 25)
        }
    }
}
