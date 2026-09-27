//
//  PasscodeEntryView.swift
//  Dijital Ajanda
//
//  iPhone'un şifre ekranı gibi: başlık, 4 nokta ve yuvarlak rakam tuşları.
//  Kilit ekranında ve ilk kurulumda (şifre oluştururken) ortak kullanılır.
//

import SwiftUI

struct PasscodeEntryView<Leading: View>: View {
    let title: String
    let subtitle: String?
    let message: String?
    @Binding var code: String
    /// Her yanlış girişte artar; noktalar sallanır.
    let shakes: Int
    let isDisabled: Bool
    let leadingKey: Leading
    /// 4. rakam girilince çağrılır.
    let onComplete: (String) -> Void

    static var length: Int { 4 }

    init(
        title: String,
        subtitle: String? = nil,
        message: String? = nil,
        code: Binding<String>,
        shakes: Int,
        isDisabled: Bool = false,
        @ViewBuilder leadingKey: () -> Leading,
        onComplete: @escaping (String) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.message = message
        self._code = code
        self.shakes = shakes
        self.isDisabled = isDisabled
        self.leadingKey = leadingKey()
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { proxy in
            let keySize = max(58, min(80, (proxy.size.height - 250) / 4.4))

            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(spacing: 8) {
                    Text(title)
                        .font(Theme.serif(26, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.serif(15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                dots
                    .padding(.top, 26)
                    .modifier(ShakeEffect(shakes: shakes))

                Text(message ?? " ")
                    .font(Theme.serif(15, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 22)
                    .padding(.top, 14)
                    .padding(.horizontal, 24)

                // İPad gibi uzun ekranlarda bu boşluk sınırsız büyümesin, yoksa tuş takımı ekranın
                // en dibine yapışır; kalan boşluk aşağıdaki boş Spacer'a paylaşılsın.
                Spacer(minLength: 8)
                    .frame(maxHeight: 90)

                keypad(size: keySize)
                    .padding(.bottom, 12)

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.selection, trigger: code)
        .sensoryFeedback(.error, trigger: shakes)
    }

    // MARK: - Noktalar

    private var dots: some View {
        HStack(spacing: 22) {
            ForEach(0..<Self.length, id: \.self) { index in
                Circle()
                    .strokeBorder(Theme.ink.opacity(0.8), lineWidth: 1.5)
                    .background(Circle().fill(index < code.count ? Theme.ink : Color.clear))
                    .frame(width: 16, height: 16)
            }
        }
        .animation(.easeOut(duration: 0.12), value: code)
        .accessibilityElement()
        .accessibilityLabel("Şifre")
        .accessibilityValue("\(code.count) / \(Self.length) hane girildi")
    }

    // MARK: - Tuş takımı

    private func keypad(size: CGFloat) -> some View {
        VStack(spacing: 16) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]], id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { digit in
                        digitKey(digit, size: size)
                    }
                }
            }
            HStack(spacing: 24) {
                leadingKey
                    .frame(width: size, height: size)
                digitKey("0", size: size)
                deleteKey(size: size)
            }
        }
    }

    private func digitKey(_ digit: String, size: CGFloat) -> some View {
        Button {
            append(digit)
        } label: {
            Text(digit)
                .font(Theme.serif(size * 0.46, weight: .light))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(KeyPressStyle())
        .disabled(isDisabled)
        .accessibilityLabel(digit)
    }

    @ViewBuilder
    private func deleteKey(size: CGFloat) -> some View {
        if code.isEmpty {
            Color.clear.frame(width: size, height: size)
        } else {
            Button {
                code.removeLast()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Theme.ink)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
            }
            .buttonStyle(KeyPressStyle())
            .disabled(isDisabled)
            .accessibilityLabel("Sil")
        }
    }

    private func append(_ digit: String) {
        guard !isDisabled, code.count < Self.length else { return }
        code.append(digit)
        guard code.count == Self.length else { return }
        let entered = code
        // Dördüncü nokta dolsun, sonra doğrula.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onComplete(entered)
        }
    }
}

/// Basılınca hafifçe küçülen ve açılan tuş.
struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Yanlış şifrede noktaları yana doğru sallar.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    init(shakes: Int) {
        animatableData = CGFloat(shakes)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 12 * sin(animatableData * .pi * 4), y: 0))
    }
}
