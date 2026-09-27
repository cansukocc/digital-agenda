//
//  MonthsIndexView.swift
//  Dijital Ajanda
//
//  Ajandanın ilk sayfası ve her ay bitiminde tekrar açılan aylar tablosu.
//

import SwiftUI

struct MonthsIndexView: View {
    /// Tablonun ardından başlayacak ay; tabloda vurgulanır.
    let focus: Date
    let open: (Date) -> Void

    private static let cellHeight: CGFloat = 84

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ajanda")
                        .font(Theme.serif(40, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text("\(AgendaFormat.monthAndYear(AgendaCalendar.start)) – \(AgendaFormat.monthAndYear(AgendaCalendar.end))")
                        .font(Theme.serif(16))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.bottom, 18)

                ForEach(years, id: \.year) { group in
                    Text(group.year)
                        .font(Theme.serif(22, weight: .light))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                    table(group.months)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    /// Aylar üçer sütunluk bir tablo olarak dizilir.
    private func table(_ months: [Date]) -> some View {
        let rows = stride(from: 0, to: months.count, by: 3).map { Array(months[$0..<min($0 + 3, months.count)]) }
        return VStack(spacing: 0) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { column in
                        if column < row.count {
                            cell(row[column])
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: Self.cellHeight, maxHeight: Self.cellHeight)
                        }
                    }
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 0).stroke(Theme.rule, lineWidth: 1)
        }
    }

    private func cell(_ month: Date) -> some View {
        let isFocus = AgendaCalendar.sameDay(month, focus)
        let isCurrent = AgendaCalendar.sameDay(month, AgendaCalendar.monthStart(AgendaCalendar.today))
        let number = AgendaCalendar.calendar.component(.month, from: month)

        return Button {
            open(month)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(String(format: "%02d", number))
                        .font(Theme.serif(12))
                        .foregroundStyle(isFocus ? Theme.paper.opacity(0.85) : Theme.inkSoft)
                    Spacer()
                    if isCurrent {
                        Circle()
                            .fill(isFocus ? Theme.paper : Theme.accent)
                            .frame(width: 6, height: 6)
                            .accessibilityLabel("Bu ay")
                    }
                }
                Text(AgendaFormat.month(month))
                    .font(Theme.serif(21, weight: .medium))
                    .foregroundStyle(isFocus ? Theme.paper : Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: Self.cellHeight, maxHeight: Self.cellHeight, alignment: .topLeading)
            .background(isFocus ? Theme.accent : Color.clear)
            .contentShape(Rectangle())
            .overlay {
                Rectangle().stroke(Theme.rule, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}
