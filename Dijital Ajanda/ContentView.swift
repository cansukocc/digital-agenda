//
//  ContentView.swift
//  Dijital Ajanda
//
//  Created by Cansu Koç on 21.09.2026.
//

import SwiftUI

struct ContentView: View {
    /// Ajanda bugünün sayfasıyla açılır.
    @State private var page: AgendaPage = .day(AgendaCalendar.home)

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                TopBar(page: page, go: go)
                content
                    .id(page)
                    .transition(.opacity)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.paper)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 2)
            }
            .padding(.leading, 10)
            .padding(.vertical, 10)

            SideRail(page: page, go: go)
                .padding(.top, 36)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Theme.desk.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .months(let month):
            MonthsIndexView(focus: month) { go(.month($0)) }
        case .day(let day):
            DayPageView(date: day)
        case .week(let day):
            WeekPageView(date: day) { go(.day($0)) }
        case .month(let day):
            MonthPageView(date: day, openDay: { go(.day($0)) }, openWeek: { go(.week($0)) })
        case .journal(let number):
            JournalPageView(number: number)
        }
    }

    private func go(_ target: AgendaPage) {
        withAnimation(.easeInOut(duration: 0.18)) {
            page = target
        }
    }
}

/// Üstteki çubuk: sol ok önceki sayfaya, sağ ok sonraki sayfaya götürür.
private struct TopBar: View {
    let page: AgendaPage
    let go: (AgendaPage) -> Void

    var body: some View {
        HStack {
            arrow("chevron.left", label: "Önceki", target: page.previous)
            Spacer()
            Text(page.title)
                .font(Theme.serif(17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            arrow("chevron.right", label: "Sonraki", target: page.next)
        }
        .padding(.horizontal, 4)
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.rule).frame(height: 1)
        }
    }

    private func arrow(_ symbol: String, label: String, target: AgendaPage?) -> some View {
        Button {
            if let target { go(target) }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .disabled(target == nil)
        .opacity(target == nil ? 0.25 : 1)
        .accessibilityLabel(label)
    }
}

/// Sayfanın kenarındaki sekmeler: bugün, görünüm değiştirme (gün → hafta → ay), aylar, günlük.
private struct SideRail: View {
    let page: AgendaPage
    let go: (AgendaPage) -> Void

    var body: some View {
        VStack(spacing: 8) {
            tab("Bugün", icon: "sun.max", isActive: false) {
                go(.day(AgendaCalendar.home))
            }
            tab(page.cycled.viewName, icon: page.cycled.viewIcon, isActive: false) {
                go(page.cycled)
            }
            tab("Aylar", icon: "tablecells", isActive: page.isMonthsTable) {
                go(.months(page.monthAnchor))
            }
            tab("Günlük", icon: "book", isActive: page.isJournal) {
                go(.journal(1))
            }
        }
    }

    private func tab(_ title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isActive ? Theme.accent : Theme.paper)
            .frame(width: 54, height: 58)
            .background(
                isActive ? Theme.paper : Theme.accent,
                in: UnevenRoundedRectangle(bottomTrailingRadius: 12, topTrailingRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview {
    ContentView()
        .environment(NoteStore())
}
