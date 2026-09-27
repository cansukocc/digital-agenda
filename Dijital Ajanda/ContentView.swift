//
//  ContentView.swift
//  Dijital Ajanda
//
//  Created by Cansu Koç on 21.09.2026.
//

import SwiftUI

struct ContentView: View {
    /// Ajanda (şifre girildikten sonra) kapakla açılır; kapak kaydırılınca takvim, sonra günler gelir.
    @State private var page: AgendaPage = .cover

    /// "" = cihazın temasını izle, "light" = açık, "dark" = koyu. Düğmeyle değiştirilince saklanır.
    @AppStorage("appearance") private var appearance = ""

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !page.isCover {
                    TopBar(page: page, go: go)
                }
                content
                    .id(page)
                    .transition(.opacity)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.paper)
                    .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
            }
            .padding(.leading, 10)
            .padding(.trailing, page.isCover ? 10 : 0)
            .padding(.vertical, 10)

            // Kenar sekmeleri kapakta görünmez, ajanda açılınca belirir.
            if !page.isCover {
                SideRail(page: page, go: go) { current in
                    appearance = current == .dark ? "light" : "dark"
                }
                .padding(.top, 36)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(Theme.desk.ignoresSafeArea())
        .preferredColorScheme(preferredScheme)
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .cover:
            // Kapak kaydırılırken altında bir sonraki sayfa (takvim) görünür.
            ZStack {
                YearCalendarView(openDay: { _ in }, openMonth: { _ in })
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                CoverPageView { go(.calendar) }
            }
        case .calendar:
            YearCalendarView(openDay: { go(.day($0)) }, openMonth: { go(.month($0)) })
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

/// Sayfanın kenarındaki sekmeler, kitabın sırasıyla: kapak, takvim, ay, hafta, bugün, günlük sayfaları.
/// En altta tema düğmesi. Ekran kısaysa (yatay iPhone) kaydırılır.
private struct SideRail: View {
    let page: AgendaPage
    let go: (AgendaPage) -> Void
    let toggleTheme: (ColorScheme) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                tab("Kapak", icon: "book.closed", isActive: page.isCover) {
                    go(.cover)
                }
                tab("Takvim", icon: "rectangle.grid.3x2", isActive: page.isCalendar) {
                    go(.calendar)
                }
                tab("Ay", icon: "calendar", isActive: page.isMonth) {
                    go(.month(page.anchorDate))
                }
                tab("Hafta", icon: "list.bullet.rectangle", isActive: page.isWeek) {
                    go(.week(page.anchorDate))
                }
                tab("Bugün", icon: "house", isActive: page.isDay) {
                    go(.day(AgendaCalendar.home))
                }
                tab("Günlük", icon: "pencil.line", isActive: page.isJournal) {
                    go(.journal(1))
                }

                roundButton(
                    icon: colorScheme == .dark ? "sun.max.fill" : "moon.stars.fill",
                    label: colorScheme == .dark ? "Açık temaya geç" : "Koyu temaya geç",
                    isActive: false
                ) {
                    toggleTheme(colorScheme)
                }
                .frame(width: 54)
                .padding(.top, 6)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func roundButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(isActive ? Theme.accent : Theme.paper)
                .frame(width: 40, height: 40)
                .background(isActive ? Theme.paper : Theme.accent, in: Circle())
                .overlay {
                    if isActive { Circle().strokeBorder(Theme.accent, lineWidth: 1.5) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
