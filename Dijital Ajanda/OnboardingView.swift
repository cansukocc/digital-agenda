//
//  OnboardingView.swift
//  Dijital Ajanda
//
//  İlk açılış: iPhone'daki gibi şifre oluştur, tekrar gir; cihazda Face ID varsa onunla da açılsın mı diye sorar.
//

import SwiftUI

struct OnboardingView: View {
    private enum Step {
        case create
        case confirm
        case biometrics
    }

    @Environment(LockManager.self) private var lock

    @State private var step: Step = .create
    @State private var firstCode = ""
    @State private var code = ""
    @State private var shakes = 0
    @State private var message: String?
    @State private var isBusy = false

    var body: some View {
        ZStack {
            LockBackground()

            VStack(spacing: 0) {
                AppMark()
                    .padding(.top, 28)

                Group {
                    switch step {
                    case .create:
                        PasscodeEntryView(
                            title: "Şifre Oluştur",
                            subtitle: "Ajandanı korumak için 4 haneli bir şifre belirle. Unutursan ajanda sıfırlanır.",
                            message: message,
                            code: $code,
                            shakes: shakes,
                            isDisabled: isBusy,
                            leadingKey: { Color.clear },
                            onComplete: created
                        )
                    case .confirm:
                        PasscodeEntryView(
                            title: "Şifreyi Tekrar Gir",
                            subtitle: "Aynı şifreyi bir kez daha gir.",
                            message: message,
                            code: $code,
                            shakes: shakes,
                            isDisabled: isBusy,
                            leadingKey: { backKey },
                            onComplete: confirmed
                        )
                    case .biometrics:
                        biometricsOffer
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Adımlar

    private var backKey: some View {
        Button {
            code = ""
            message = nil
            firstCode = ""
            step = .create
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Theme.ink)
                .contentShape(Circle())
        }
        .buttonStyle(KeyPressStyle())
        .accessibilityLabel("Geri")
    }

    private func created(_ entered: String) {
        firstCode = entered
        code = ""
        message = nil
        step = .confirm
    }

    private func confirmed(_ entered: String) {
        if entered == firstCode {
            if Biometrics.isAvailable {
                code = ""
                step = .biometrics
            } else {
                finish(faceID: false)
            }
            return
        }

        // Eşleşmedi: salla, mesajı göster, baştan başla.
        isBusy = true
        message = "Şifreler eşleşmedi. Baştan dene."
        withAnimation(.linear(duration: 0.45)) {
            shakes += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            code = ""
            firstCode = ""
            message = nil
            isBusy = false
            step = .create
        }
    }

    private var biometricsOffer: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: Biometrics.symbol)
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(Theme.ink)
            Text("\(Biometrics.name) ile aç")
                .font(Theme.serif(28, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)
            Text("Şifre girmeden ajandanı \(Biometrics.name) ile açabilirsin. Şifren yine de geçerli kalır.")
                .font(Theme.serif(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)
            Spacer()

            Button {
                Task {
                    let ok = await Biometrics.authenticate(reason: "Ajandayı \(Biometrics.name) ile açabilmek için")
                    finish(faceID: ok)
                }
            } label: {
                Text("\(Biometrics.name)'yi aç")
                    .font(Theme.serif(18, weight: .semibold))
                    .foregroundStyle(Theme.paper)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: Capsule())
            }

            Button("Şimdi değil") {
                finish(faceID: false)
            }
            .font(Theme.serif(16))
            .foregroundStyle(Theme.ink.opacity(0.85))
            .padding(.vertical, 18)
            .padding(.bottom, 12)
        }
    }

    private func finish(faceID: Bool) {
        guard !lock.completeOnboarding(pin: firstCode, faceID: faceID) else { return }

        // Şifre cihazın Anahtar Zinciri'ne yazılamadı: kullanıcıyı sessizce takılı bırakma.
        code = ""
        firstCode = ""
        message = "Şifre kaydedilemedi. Tekrar dene."
        step = .create
    }
}
