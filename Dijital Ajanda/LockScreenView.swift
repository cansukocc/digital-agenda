//
//  LockScreenView.swift
//  Dijital Ajanda
//
//  Kilit ekranı: iPhone'un şifre ekranı gibi. Zemin uygulamanın temasını izler
//  (açıkta pembe gradyan, koyuda sıcak kömür). Face ID açıksa ekran açılınca kendiliğinden denenir.
//

import SwiftUI

/// Kilit ve ilk kurulum ekranlarının gradyan zemini.
struct LockBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.lockTop, Theme.lockBottom], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Theme.accent.opacity(0.28))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: -120, y: -260)
            Circle()
                .fill(Theme.paper.opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 140, y: 300)
        }
        .ignoresSafeArea()
    }
}

/// Uygulama arka plandayken ya da uygulama değiştiricide görünen örtü: içerik gizlenir.
struct PrivacyCover: View {
    var body: some View {
        ZStack {
            LockBackground()
            AppMark()
        }
    }
}

/// Kilit ekranlarının üstündeki küçük "Ajanda" işareti.
struct AppMark: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.ink.opacity(0.85))
            Text("Ajanda")
                .font(Theme.serif(34, weight: .medium))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LockScreenView: View {
    @Environment(LockManager.self) private var lock
    @Environment(NoteStore.self) private var notes

    @State private var code = ""
    @State private var shakes = 0
    @State private var message: String?
    /// Yanlış girişten sonra noktalar sallanıp temizlenirken tuşlar kapalıdır.
    @State private var isBusy = false
    @State private var now = Date()
    @State private var confirmReset = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var remainingWait: Int {
        guard let until = lock.lockedUntil else { return 0 }
        return max(0, Int(until.timeIntervalSince(now).rounded(.up)))
    }

    var body: some View {
        ZStack {
            LockBackground()

            VStack(spacing: 0) {
                AppMark()
                    .padding(.top, 28)

                PasscodeEntryView(
                    title: "Şifreyi Gir",
                    message: remainingWait > 0 ? "Çok fazla deneme. \(remainingWait) saniye sonra tekrar dene." : message,
                    code: $code,
                    shakes: shakes,
                    isDisabled: isBusy || remainingWait > 0,
                    leadingKey: { biometricKey },
                    onComplete: submit
                )

                Button("Şifremi unuttum") {
                    confirmReset = true
                }
                .font(Theme.serif(15))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .padding(.bottom, 20)
            }
        }
        .onReceive(ticker) { now = $0 }
        .task { await tryBiometricsOnAppear() }
        .alert("Ajandayı sıfırla?", isPresented: $confirmReset) {
            Button("Vazgeç", role: .cancel) {}
            Button("Her şeyi sil", role: .destructive) {
                notes.reset()
                lock.resetEverything()
                // Renk ve ana ekran ikonu da varsayılana döner.
                ThemeState.shared.reload()
                AppIconSwitcher.apply(colorID: ThemeState.shared.colorID)
            }
        } message: {
            Text("Şifreni unuttuysan tek yol ajandayı sıfırlamak. Bütün notların, yapılacakların ve ayarların silinir. Bu geri alınamaz.")
        }
    }

    // MARK: - Face ID

    @ViewBuilder
    private var biometricKey: some View {
        if lock.isFaceIDEnabled && Biometrics.isAvailable {
            Button {
                Task { await unlockWithBiometrics() }
            } label: {
                Image(systemName: Biometrics.symbol)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Theme.ink)
                    .contentShape(Circle())
            }
            .buttonStyle(KeyPressStyle())
            .accessibilityLabel("\(Biometrics.name) ile aç")
        } else {
            Color.clear
        }
    }

    private func tryBiometricsOnAppear() async {
        guard lock.isFaceIDEnabled, Biometrics.isAvailable else { return }
        // Ekran otursun, sonra iPhone'daki gibi kendiliğinden dene.
        try? await Task.sleep(nanoseconds: 350_000_000)
        await unlockWithBiometrics()
    }

    private func unlockWithBiometrics() async {
        if await Biometrics.authenticate(reason: "Ajandayı açmak için") {
            lock.unlockAfterBiometrics()
        }
    }

    // MARK: - Şifre

    private func submit(_ entered: String) {
        now = Date()
        switch lock.attempt(entered) {
        case .success:
            break
        case .wrong:
            fail(with: "Yanlış şifre")
        case .throttled:
            fail(with: nil)
        }
    }

    /// Noktaları salla, sonra temizle.
    private func fail(with text: String?) {
        isBusy = true
        message = text
        withAnimation(.linear(duration: 0.45)) {
            shakes += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            code = ""
            isBusy = false
        }
    }
}
