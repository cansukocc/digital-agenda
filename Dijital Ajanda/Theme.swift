//
//  Theme.swift
//  Dijital Ajanda
//
//  Uygulamanın renkleri. Hepsi seçilen kapak renginden üretilir (PaletteMath.swift):
//  açık temada rengin çok açık tonları zemin, koyu tonu vurgu olur; koyu temada zemin kömür renginde kalır.
//

import Observation
import SwiftUI
import UIKit

/// Seçili kapak rengi. Değişince, renkleri okuyan bütün görünümler kendiliğinden yenilenir.
@Observable
final class ThemeState {
    static let shared = ThemeState()
    private static let storageKey = "coverColor"

    private(set) var colorID: String

    private init() {
        colorID = Self.storedID()
    }

    private static func storedID() -> String {
        let id = UserDefaults.standard.string(forKey: storageKey) ?? CoverPalette.defaultID
        return CoverPalette.all.contains { $0.id == id } ? id : CoverPalette.defaultID
    }

    func select(_ id: String) {
        guard id != colorID else { return }
        colorID = id
        UserDefaults.standard.set(id, forKey: Self.storageKey)
    }

    /// Ayarlar silindikten sonra (sıfırlama) kayıtlı renge, yoksa varsayılana döner.
    func reload() {
        colorID = Self.storedID()
    }

    var palette: AppPalette { AppPalette.cached(for: colorID) }
}

/// Bir kapak renginden üretilmiş, açık ve koyu temayı içeren hazır renkler.
struct AppPalette {
    let desk: Color
    let paper: Color
    let ink: Color
    let inkSoft: Color
    let rule: Color
    let accent: Color
    let lockTop: Color
    let lockBottom: Color
    let shadow: Color

    // Metin görünümü (UIKit) için
    let inkUI: UIColor
    let ruleUI: UIColor
    let accentUI: UIColor

    private static var cache: [String: AppPalette] = [:]

    static func cached(for id: String) -> AppPalette {
        if let palette = cache[id] { return palette }
        let palette = AppPalette(spec: PaletteSpec.make(from: CoverPalette.color(for: id).rgb))
        cache[id] = palette
        return palette
    }

    private static func dynamic(_ light: RGB, _ dark: RGB, alpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: alpha)
        }
    }

    private init(spec: PaletteSpec) {
        let light = spec.light, dark = spec.dark
        inkUI = Self.dynamic(light.ink, dark.ink)
        ruleUI = Self.dynamic(light.rule, dark.rule)
        accentUI = Self.dynamic(light.accent, dark.accent)

        desk = Color(uiColor: Self.dynamic(light.desk, dark.desk))
        paper = Color(uiColor: Self.dynamic(light.paper, dark.paper))
        ink = Color(uiColor: inkUI)
        inkSoft = Color(uiColor: Self.dynamic(light.inkSoft, dark.inkSoft))
        rule = Color(uiColor: ruleUI)
        accent = Color(uiColor: accentUI)
        lockTop = Color(uiColor: Self.dynamic(light.lockTop, dark.lockTop))
        lockBottom = Color(uiColor: Self.dynamic(light.lockBottom, dark.lockBottom))
        shadow = Color(uiColor: Self.dynamic(light.accent.mixed(with: .black, 0.4), .black, alpha: 0.22))
    }
}

/// Görünümlerin kullandığı renkler. Bir görünümün içinde okununca seçili renk değişince o görünüm yenilenir.
enum Theme {
    private static var palette: AppPalette { ThemeState.shared.palette }

    static var desk: Color { palette.desk }
    static var paper: Color { palette.paper }
    static var ink: Color { palette.ink }
    static var inkSoft: Color { palette.inkSoft }
    static var rule: Color { palette.rule }
    static var accent: Color { palette.accent }
    static var lockTop: Color { palette.lockTop }
    static var lockBottom: Color { palette.lockBottom }
    static var shadow: Color { palette.shadow }

    static var inkUI: UIColor { palette.inkUI }
    static var ruleUI: UIColor { palette.ruleUI }
    static var accentUI: UIColor { palette.accentUI }

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Ana ekran ikonunu seçilen kapak rengine göre değiştirir (iOS her değişimde kısa bir bildirim gösterir).
enum AppIconSwitcher {
    static func apply(colorID: String) {
        let application = UIApplication.shared
        guard application.supportsAlternateIcons else { return }
        let target: String? = colorID == CoverPalette.defaultID ? nil : "AppIcon-\(colorID)"
        guard application.alternateIconName != target else { return }
        application.setAlternateIconName(target) { _ in }
    }
}
