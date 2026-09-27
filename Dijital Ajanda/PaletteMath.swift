//
//  PaletteMath.swift
//  Dijital Ajanda
//
//  Seçilen kapak renginden uygulamanın bütün renk paletini üretir (açık ve koyu tema için).
//  Yalnızca renk hesabıdır; ekranla ilgisi yoktur.
//

import Foundation

struct RGB: Equatable {
    var r: Double
    var g: Double
    var b: Double

    /// Göreli parlaklık (WCAG): kontrast hesabı için.
    var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    func mixed(with other: RGB, _ amount: Double) -> RGB {
        RGB(r: r + (other.r - r) * amount, g: g + (other.g - g) * amount, b: b + (other.b - b) * amount)
    }

    static let white = RGB(r: 1, g: 1, b: 1)
    static let black = RGB(r: 0, g: 0, b: 0)
}

struct HSB {
    var h: Double
    var s: Double
    var b: Double

    init(h: Double, s: Double, b: Double) {
        self.h = h - floor(h)
        self.s = min(max(s, 0), 1)
        self.b = min(max(b, 0), 1)
    }

    init(_ rgb: RGB) {
        let maxV = max(rgb.r, rgb.g, rgb.b)
        let minV = min(rgb.r, rgb.g, rgb.b)
        let delta = maxV - minV
        var hue = 0.0
        if delta > 0 {
            if maxV == rgb.r {
                hue = ((rgb.g - rgb.b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxV == rgb.g {
                hue = (rgb.b - rgb.r) / delta + 2
            } else {
                hue = (rgb.r - rgb.g) / delta + 4
            }
            hue /= 6
        }
        self.init(h: hue, s: maxV == 0 ? 0 : delta / maxV, b: maxV)
    }

    var rgb: RGB {
        let c = b * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        let (r, g, bl): (Double, Double, Double)
        switch Int(h * 6) % 6 {
        case 0: (r, g, bl) = (c, x, 0)
        case 1: (r, g, bl) = (x, c, 0)
        case 2: (r, g, bl) = (0, c, x)
        case 3: (r, g, bl) = (0, x, c)
        case 4: (r, g, bl) = (x, 0, c)
        default: (r, g, bl) = (c, 0, x)
        }
        return RGB(r: r + m, g: g + m, b: bl + m)
    }
}

/// Bir temanın (açık ya da koyu) bütün renkleri.
struct SchemeColors {
    var desk: RGB
    var paper: RGB
    var ink: RGB
    var inkSoft: RGB
    var rule: RGB
    var accent: RGB
    var lockTop: RGB
    var lockBottom: RGB
}

struct PaletteSpec {
    var light: SchemeColors
    var dark: SchemeColors

    /// Kapak renginden palet üretir: açık temada rengin çok açık tonları zemin, koyu tonu vurgu olur;
    /// koyu temada zemin kömür renginde kalır ama hafifçe renkle tonlanır, vurgu rengin açık tonu olur.
    static func make(from base: RGB) -> PaletteSpec {
        let hsb = HSB(base)
        let neutral = hsb.s < 0.12
        let tint = neutral ? 0.02 : min(max(hsb.s * 0.5, 0.10), 0.22)
        let darkTint = neutral ? 0.02 : min(hsb.s, 0.4) * 0.25

        // Açık tema vurgusu: beyaz yazıyla okunacak kadar koyu (kontrast ≥ ~4).
        let lightSat = neutral ? hsb.s : min(max(hsb.s, 0.55), 0.85)
        var lightBrightness = neutral ? 0.30 : min(max(hsb.b, 0.6), 0.92)
        while HSB(h: hsb.h, s: lightSat, b: lightBrightness).rgb.luminance > 0.30 && lightBrightness > 0.2 {
            lightBrightness -= 0.02
        }
        let lightAccent = HSB(h: hsb.h, s: lightSat, b: lightBrightness).rgb

        // Koyu tema vurgusu: koyu zeminde okunacak kadar açık.
        let darkSat = neutral ? 0.04 : min(max(hsb.s, 0.35), 0.65)
        var darkBrightness = 0.65
        while HSB(h: hsb.h, s: darkSat, b: darkBrightness).rgb.luminance < 0.36 && darkBrightness < 1.0 {
            darkBrightness += 0.02
        }
        let darkAccent = HSB(h: hsb.h, s: darkSat, b: darkBrightness).rgb

        let inkSat = neutral ? 0.05 : max(0.45, min(hsb.s, 0.7))

        let light = SchemeColors(
            desk: HSB(h: hsb.h, s: tint, b: 0.955).rgb,
            paper: HSB(h: hsb.h, s: tint * 0.16, b: 0.995).rgb,
            ink: HSB(h: hsb.h - 0.02, s: inkSat, b: 0.27).rgb,
            inkSoft: HSB(h: hsb.h, s: inkSat * 0.55, b: 0.52).rgb,
            rule: HSB(h: hsb.h, s: tint * 0.9, b: 0.92).rgb,
            accent: lightAccent,
            lockTop: HSB(h: hsb.h, s: tint * 1.6, b: 1.0).rgb,
            lockBottom: HSB(h: hsb.h, s: neutral ? 0.05 : min(max(hsb.s * 1.1, 0.42), 0.6), b: 0.90).rgb
        )
        let dark = SchemeColors(
            desk: HSB(h: hsb.h, s: darkTint, b: 0.055).rgb,
            paper: HSB(h: hsb.h, s: darkTint, b: 0.135).rgb,
            ink: HSB(h: hsb.h, s: 0.06, b: 0.93).rgb,
            inkSoft: HSB(h: hsb.h, s: 0.10, b: 0.66).rgb,
            rule: HSB(h: hsb.h, s: darkTint * 1.2, b: 0.27).rgb,
            accent: darkAccent,
            lockTop: HSB(h: hsb.h, s: neutral ? 0.03 : min(max(hsb.s * 0.5, 0.1), 0.35), b: 0.22).rgb,
            lockBottom: HSB(h: hsb.h, s: neutral ? 0.02 : min(hsb.s * 0.25, 0.2), b: 0.05).rgb
        )
        return PaletteSpec(light: light, dark: dark)
    }
}
