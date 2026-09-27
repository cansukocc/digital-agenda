//
//  CoverPageView.swift
//  Dijital Ajanda
//
//  Ajandanın kapağı. Sola kaydırılınca kapak sırtından açılır ve ajanda görünür.
//  Köşedeki palet düğmesi renk ve isim düzenleme sayfasını açar.
//

import SwiftUI

/// Kapak için seçilebilen hazır renkler.
struct CoverColor: Identifiable, Hashable {
    let id: String
    let name: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }

    var rgb: RGB { RGB(r: red, g: green, b: blue) }

    /// Açık renkli kapakta koyu, koyu renkli kapakta krem yazı okunur.
    var isLight: Bool { 0.299 * red + 0.587 * green + 0.114 * blue > 0.6 }

    var textColor: Color {
        isLight ? Color(red: 0.26, green: 0.12, blue: 0.20) : Color(red: 1.0, green: 0.96, blue: 0.94)
    }

    /// Beyaza ya da siyaha doğru karıştırılmış ton (kapaktaki geçiş için).
    func mixed(with target: Double, amount: Double) -> Color {
        Color(
            red: red + (target - red) * amount,
            green: green + (target - green) * amount,
            blue: blue + (target - blue) * amount
        )
    }
}

enum CoverPalette {
    /// İlk altı pastel, son altı klasik (koyu) renk.
    static let all: [CoverColor] = [
        CoverColor(id: "pudra", name: "Pudra", red: 0.96, green: 0.72, blue: 0.79),
        CoverColor(id: "seftali", name: "Şeftali", red: 0.98, green: 0.72, blue: 0.60),
        CoverColor(id: "vanilya", name: "Vanilya", red: 0.97, green: 0.86, blue: 0.55),
        CoverColor(id: "nane", name: "Nane", red: 0.62, green: 0.85, blue: 0.74),
        CoverColor(id: "bebek", name: "Bebek mavisi", red: 0.62, green: 0.78, blue: 0.92),
        CoverColor(id: "lavanta", name: "Lavanta", red: 0.72, green: 0.66, blue: 0.90),
        CoverColor(id: "bordo", name: "Bordo", red: 0.45, green: 0.10, blue: 0.18),
        CoverColor(id: "lacivert", name: "Lacivert", red: 0.11, green: 0.17, blue: 0.35),
        CoverColor(id: "orman", name: "Orman yeşili", red: 0.10, green: 0.30, blue: 0.22),
        CoverColor(id: "kahve", name: "Kahve deri", red: 0.37, green: 0.22, blue: 0.14),
        CoverColor(id: "mor", name: "Mor", red: 0.30, green: 0.16, blue: 0.38),
        CoverColor(id: "siyah", name: "Siyah", red: 0.10, green: 0.10, blue: 0.11),
    ]

    static let defaultID = "pudra"

    static func color(for id: String) -> CoverColor {
        all.first { $0.id == id } ?? all[0]
    }
}

struct CoverPageView: View {
    /// Kapak tamamen açılınca çağrılır.
    let onOpen: () -> Void

    /// Seçili kapak rengi bütün uygulamanın rengini belirler.
    private let theme = ThemeState.shared
    @AppStorage("coverName") private var name = ""

    /// Kapağın ne kadar açıldığı: 0 = kapalı, 1 = tamamen açık.
    @State private var progress: Double = 0
    @State private var isOpening = false
    /// Kapalıyken arada bir hafifçe kıpırdayarak kaydırılabileceğini hissettirir.
    @State private var wiggle: Double = 0
    @State private var showEditor = false

    private static let spineWidth: CGFloat = 26

    var body: some View {
        let cover = CoverPalette.color(for: theme.colorID)
        let ink = cover.textColor

        GeometryReader { proxy in
            content(cover: cover, ink: ink)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background { background(cover, ink: ink) }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3 * progress), radius: 14, x: 6, y: 0)
                .rotation3DEffect(
                    .degrees(-(88 * progress) - wiggle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.2
                )
                .opacity(1 - max(0, (progress - 0.92) / 0.08))
                .gesture(openGesture(width: proxy.size.width))
        }
        .task { await wiggleLoop() }
        .sheet(isPresented: $showEditor, onDismiss: {
            // Ana ekran ikonu da seçilen renge geçer (yalnızca düzenleme bitince, bir kez).
            AppIconSwitcher.apply(colorID: theme.colorID)
        }) {
            CoverEditor(
                colorID: Binding(get: { theme.colorID }, set: { theme.select($0) }),
                name: $name
            )
        }
        .accessibilityAction(named: "Ajandayı aç") { open() }
    }

    // MARK: - Açma hareketi

    private func openGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !isOpening else { return }
                progress = min(1, max(0, -value.translation.width / (width * 0.75)))
            }
            .onEnded { value in
                guard !isOpening else { return }
                let flicked = -value.predictedEndTranslation.width > width * 0.5
                if progress > 0.35 || flicked {
                    open()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        progress = 0
                    }
                }
            }
    }

    private func open() {
        guard !isOpening else { return }
        isOpening = true
        withAnimation(.easeIn(duration: 0.3)) {
            progress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            onOpen()
        }
    }

    /// Birkaç saniyede bir kapak sırtından hafifçe aralanıp geri kapanır.
    private func wiggleLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !isOpening, progress == 0, !showEditor else { continue }
            withAnimation(.easeOut(duration: 0.35)) { wiggle = 9 }
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.easeInOut(duration: 0.5)) { wiggle = 0 }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    // MARK: - Kapağın görünümü

    private func content(cover: CoverColor, ink: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                titleBlock(ink)
                Spacer(minLength: 24)
                nameButton(ink)
                Spacer(minLength: 24)
                swipeHint(ink)
                    .padding(.bottom, 34)
            }
            .padding(.leading, Self.spineWidth + 34)
            .padding(.trailing, 32)

            paletteButton(ink)
                .padding(.top, 26)
                .padding(.trailing, 26)
        }
    }

    private func background(_ cover: CoverColor, ink: Color) -> some View {
        ZStack {
            LinearGradient(
                colors: [cover.mixed(with: 1, amount: 0.10), cover.color, cover.mixed(with: 0, amount: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Cilt: soldaki sırt ve dikiş
            HStack(spacing: 0) {
                ZStack {
                    Rectangle().fill(Color.black.opacity(0.14))
                    Path { path in
                        path.move(to: CGPoint(x: Self.spineWidth / 2, y: 18))
                        path.addLine(to: CGPoint(x: Self.spineWidth / 2, y: 4000))
                    }
                    .stroke(ink.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
                }
                .frame(width: Self.spineWidth)
                Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1)
                Spacer()
            }

            // Kapağın içindeki ince çerçeve
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(ink.opacity(0.35), lineWidth: 1)
                .padding(EdgeInsets(top: 16, leading: Self.spineWidth + 16, bottom: 16, trailing: 16))
        }
    }

    private func titleBlock(_ ink: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(ink.opacity(0.85))
            Text("Ajanda")
                .font(Theme.serif(58, weight: .medium))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Rectangle()
                .fill(ink.opacity(0.5))
                .frame(width: 56, height: 1)
            Text("\(AgendaFormat.fullDay(AgendaCalendar.start)) – \(AgendaFormat.fullDay(AgendaCalendar.end))")
                .font(Theme.serif(16))
                .foregroundStyle(ink.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    /// Kapaktaki isim; dokununca düzenleme sayfası açılır.
    private func nameButton(_ ink: Color) -> some View {
        Button {
            showEditor = true
        } label: {
            VStack(spacing: 6) {
                Text(name.isEmpty ? "Adını yaz" : name)
                    .font(Theme.serif(24).italic())
                    .foregroundStyle(name.isEmpty ? ink.opacity(0.5) : ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(ink.opacity(0.4))
                    .frame(height: 1)
            }
            .frame(maxWidth: 320)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name.isEmpty ? "Kapağa isim yaz" : "Kapaktaki isim: \(name)")
    }

    private func paletteButton(_ ink: Color) -> some View {
        Button {
            showEditor = true
        } label: {
            Image(systemName: "paintpalette")
                .font(.system(size: 17))
                .foregroundStyle(ink)
                .frame(width: 42, height: 42)
                .background(ink.opacity(0.14), in: Circle())
                .overlay(Circle().strokeBorder(ink.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Kapağı düzenle: renk ve isim")
    }

    /// Alttaki kaydırma ipucu: soldan sağa akan oklar sola kaydırılacağını gösterir.
    private func swipeHint(_ ink: Color) -> some View {
        VStack(spacing: 8) {
            Text("Ajandayı açmak için kaydır")
                .font(Theme.serif(15))
                .foregroundStyle(ink.opacity(0.9))
            TimelineView(.animation) { timeline in
                let phase = (timeline.date.timeIntervalSinceReferenceDate * 0.85).truncatingRemainder(dividingBy: 1)
                let highlight = 3.0 - phase * 5.0
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        let strength = max(0, 1 - abs(Double(index) - highlight) / 1.5)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.25 + 0.75 * strength))
                            .offset(x: -3 * strength)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Renk ve isim düzenleme sayfası: alttan açılır, kapak arkada canlı olarak değişir.
private struct CoverEditor: View {
    @Binding var colorID: String
    @Binding var name: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Kapağı düzenle")
                    .font(Theme.serif(22, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button("Bitti") { dismiss() }
                    .font(Theme.serif(17, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("İsim")
                    .font(Theme.serif(13))
                    .foregroundStyle(Theme.inkSoft)
                TextField(
                    "",
                    text: $name,
                    prompt: Text("Adını yaz ya da bir cümle").foregroundStyle(Theme.inkSoft.opacity(0.7))
                )
                .font(Theme.serif(20).italic())
                .foregroundStyle(Theme.ink)
                .tint(Theme.accent)
                .submitLabel(.done)
                Rectangle().fill(Theme.rule).frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Renk")
                        .font(Theme.serif(13))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(CoverPalette.color(for: colorID).name)
                        .font(Theme.serif(13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 14) {
                    ForEach(CoverPalette.all) { option in
                        swatch(option)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .presentationDetents([.height(350), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.paper)
    }

    private func swatch(_ option: CoverColor) -> some View {
        let isSelected = option.id == colorID
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                colorID = option.id
            }
        } label: {
            ZStack {
                Circle().fill(option.color)
                Circle().strokeBorder(Theme.ink.opacity(0.2), lineWidth: 1)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(option.textColor)
                }
            }
            .frame(width: 40, height: 40)
            .overlay {
                if isSelected {
                    Circle().strokeBorder(Theme.accent, lineWidth: 2).padding(-4)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Kapak rengi: \(option.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
