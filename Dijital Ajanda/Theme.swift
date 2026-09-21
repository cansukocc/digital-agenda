//
//  Theme.swift
//  Dijital Ajanda
//
//  Kağıt ajanda görünümü: krem sayfa, mürekkep yazı, kiremit vurgu. Koyu modda da çalışır.
//

import SwiftUI
import UIKit

enum Theme {
    private static func dynamic(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat)) -> UIColor {
        UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        }
    }

    // Metin görünümü (UIKit) için
    static let inkUI = dynamic((0.17, 0.15, 0.13), (0.93, 0.91, 0.87))
    static let ruleUI = dynamic((0.86, 0.81, 0.72), (0.27, 0.25, 0.22))

    // SwiftUI için
    static let desk = Color(uiColor: dynamic((0.83, 0.79, 0.73), (0.06, 0.06, 0.05)))
    static let paper = Color(uiColor: dynamic((0.988, 0.976, 0.949), (0.13, 0.12, 0.11)))
    static let ink = Color(uiColor: inkUI)
    static let inkSoft = Color(uiColor: dynamic((0.45, 0.41, 0.37), (0.66, 0.63, 0.58)))
    static let rule = Color(uiColor: ruleUI)
    static let accent = Color(uiColor: dynamic((0.65, 0.27, 0.19), (0.91, 0.52, 0.41)))

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
