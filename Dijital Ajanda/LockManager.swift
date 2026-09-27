//
//  LockManager.swift
//  Dijital Ajanda
//
//  Yerel kilit: ilk açılışta 4 haneli şifre belirlenir, sonra ajanda her açılışta kilitlidir.
//  Şifre düz metin olarak saklanmaz; rastgele tuzla birlikte SHA-256 özeti olarak Anahtar Zinciri'ne yazılır
//  (yalnızca bu cihazda, telefon kilitliyken erişilemez, yedeğe ve iCloud'a girmez).
//

import CryptoKit
import Foundation
import LocalAuthentication
import Observation
import Security

/// Şifrenin Anahtar Zinciri'nde saklanması.
enum PasscodeStore {
    private static let service = "com.cansukoc.Dijital-Ajanda.passcode"
    private static let account = "pin"
    private static let saltLength = 16

    private static var baseQuery: [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
    }

    static var exists: Bool { load() != nil }

    @discardableResult
    static func save(_ pin: String) -> Bool {
        var salt = Data(count: saltLength)
        let status = salt.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, saltLength, buffer.baseAddress!)
        }
        guard status == errSecSuccess else { return false }

        delete()
        var query = baseQuery
        query[kSecValueData] = salt + digest(salt: salt, pin: pin)
        query[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func verify(_ pin: String) -> Bool {
        guard let stored = load(), stored.count == saltLength + 32 else { return false }
        let salt = Data(stored.prefix(saltLength))
        return Data(stored.dropFirst(saltLength)) == digest(salt: salt, pin: pin)
    }

    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private static func load() -> Data? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func digest(salt: Data, pin: String) -> Data {
        Data(SHA256.hash(data: salt + Data(pin.utf8)))
    }
}

/// Face ID / Touch ID ile doğrulama.
enum Biometrics {
    private static func context() -> (LAContext, Bool) {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return (context, available)
    }

    static var isAvailable: Bool { context().1 }

    static var name: String {
        let (context, _) = context()
        switch context.biometryType {
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Face ID"
        }
    }

    static var symbol: String {
        let (context, _) = context()
        switch context.biometryType {
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "faceid"
        }
    }

    static func authenticate(reason: String) async -> Bool {
        let (context, available) = context()
        guard available else { return false }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)) ?? false
    }
}

@Observable
final class LockManager {
    enum State: Equatable {
        /// İlk açılış: şifre belirlenir.
        case onboarding
        case locked
        case unlocked
    }

    enum Attempt: Equatable {
        case success
        case wrong
        /// Çok fazla yanlış deneme: bu kadar saniye beklenmeli.
        case throttled(seconds: Int)
    }

    private(set) var state: State
    private(set) var lockedUntil: Date?

    @ObservationIgnored
    private let defaults: UserDefaults

    private static let installedKey = "lock.installed"
    private static let faceIDKey = "lock.faceID"
    private static let failedKey = "lock.failed"
    private static let untilKey = "lock.until"

    /// Bu kadar yanlış denemeden sonra beklemek gerekir; her yeni yanlışta bekleme ikiye katlanır.
    private static let freeAttempts = 5

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let installed = defaults.bool(forKey: Self.installedKey)
        if !installed {
            // Anahtar Zinciri uygulama silinse de kalır; önceki kurulumdan artakalan şifreyi temizle.
            PasscodeStore.delete()
        }
        state = installed && PasscodeStore.exists ? .locked : .onboarding
        lockedUntil = defaults.object(forKey: Self.untilKey) as? Date
    }

    var isFaceIDEnabled: Bool { defaults.bool(forKey: Self.faceIDKey) }

    private var failedAttempts: Int {
        get { defaults.integer(forKey: Self.failedKey) }
        set { defaults.set(newValue, forKey: Self.failedKey) }
    }

    // MARK: - İlk kurulum

    /// Şifreyi kaydeder, ajandayı açar. Şifre kaydedilemezse false döner.
    @discardableResult
    func completeOnboarding(pin: String, faceID: Bool) -> Bool {
        guard PasscodeStore.save(pin) else { return false }
        defaults.set(faceID, forKey: Self.faceIDKey)
        defaults.set(true, forKey: Self.installedKey)
        clearFailures()
        state = .unlocked
        return true
    }

    // MARK: - Kilit açma

    func attempt(_ pin: String) -> Attempt {
        if let until = lockedUntil, until > .now {
            return .throttled(seconds: Int(until.timeIntervalSinceNow.rounded(.up)))
        }
        if PasscodeStore.verify(pin) {
            clearFailures()
            state = .unlocked
            return .success
        }

        failedAttempts += 1
        guard failedAttempts >= Self.freeAttempts else { return .wrong }
        let doublings = min(failedAttempts - Self.freeAttempts, 7)
        let seconds = min(30 * (1 << doublings), 3600)
        let until = Date.now.addingTimeInterval(TimeInterval(seconds))
        lockedUntil = until
        defaults.set(until, forKey: Self.untilKey)
        return .throttled(seconds: seconds)
    }

    /// Face ID / Touch ID başarılı olunca çağrılır.
    func unlockAfterBiometrics() {
        clearFailures()
        state = .unlocked
    }

    /// Uygulama arka plana gidince ajanda hemen kilitlenir.
    func lockIfNeeded() {
        if state == .unlocked { state = .locked }
    }

    // MARK: - Sıfırlama

    /// Şifre unutulduğunda tek yol: şifreyi ve uygulamanın bütün ayarlarını siler.
    /// Notlar `NoteStore.reset()` ile ayrıca bellekten temizlenir.
    func resetEverything() {
        PasscodeStore.delete()
        if let identifier = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: identifier)
        }
        lockedUntil = nil
        state = .onboarding
    }

    private func clearFailures() {
        failedAttempts = 0
        lockedUntil = nil
        defaults.removeObject(forKey: Self.untilKey)
    }
}
