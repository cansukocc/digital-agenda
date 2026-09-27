//
//  AppRootView.swift
//  Dijital Ajanda
//
//  Uygulamanın kökü: kilit durumuna göre ilk kurulum, kilit ekranı ya da ajandayı gösterir.
//  Kilitliyken ajandanın içeriği hiç oluşturulmaz. Uygulama arka plana gidince hemen kilitlenir.
//

import SwiftUI

struct AppRootView: View {
    @Environment(LockManager.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    /// "" = cihazın temasını izle, "light" = açık, "dark" = koyu (ajandadaki tema düğmesi ayarlar).
    @AppStorage("appearance") private var appearance = ""

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            switch lock.state {
            case .onboarding:
                OnboardingView().transition(.opacity)
            case .locked:
                LockScreenView().transition(.opacity)
            case .unlocked:
                ContentView().transition(.opacity)
            }

            // Uygulama değiştiricide ya da bildirim çekilirken ajandanın içeriği görünmesin.
            if scenePhase != .active && lock.state == .unlocked {
                PrivacyCover()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lock.state)
        .preferredColorScheme(preferredScheme)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                lock.lockIfNeeded()
            }
        }
    }
}
