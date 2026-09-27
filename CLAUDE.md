# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje

Dijital Ajanda: 21 Eylül 2026 – 31 Aralık 2027 arasını kapsayan, iOS/iPadOS için SwiftUI ile yazılmış bir ajanda uygulaması. Xcode projesi (`Dijital Ajanda.xcodeproj`), tek hedef (`Dijital Ajanda`), harici paket bağımlılığı yok (SPM/CocoaPods yok). Bundle id `com.cansukoc.Dijital-Ajanda`, dağıtım hedefi iOS 17.5, Swift 5. Arayüz metinleri ve kod içi yorumlar Türkçe.

## Komutlar

Test hedefi yok (`xcodebuild -list -project "Dijital Ajanda.xcodeproj"` yalnızca `Dijital Ajanda` şemasını listeler); doğrulama derleme + simülatörde ekran görüntüsüyle elle kontrol şeklinde yapılıyor.

Hızlı derleme doğrulaması (simülatör, imzasız):
```bash
xcodebuild -project "Dijital Ajanda.xcodeproj" -scheme "Dijital Ajanda" \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  -derivedDataPath /tmp/dd build CODE_SIGNING_ALLOWED=NO
```

Belirli bir simülatörde kurup çalıştırma ve ekran görüntüsü alma (Anahtar Zinciri gerektiren kilit ekranı gibi özellikler için **imzalı** derleme şart, bkz. Kilit ekranı bölümü):
```bash
xcrun simctl list devices available          # UDID bul
xcrun simctl boot <UDID>
xcodebuild -project "Dijital Ajanda.xcodeproj" -scheme "Dijital Ajanda" \
  -destination "id=<UDID>" -configuration Debug -derivedDataPath /tmp/dd build
xcrun simctl install <UDID> "/tmp/dd/Build/Products/Debug-iphonesimulator/Dijital Ajanda.app"
xcrun simctl launch <UDID> com.cansukoc.Dijital-Ajanda
xcrun simctl io <UDID> screenshot out.png
```

Gerçek cihazda çalıştırmak için Xcode'da hedef cihazı seçip Run'a basmak yeterli; imzalama `Automatic` (takım proje ayarlarında `DEVELOPMENT_TEAM` ile sabit).

## Mimari

### Sayfa modeli: tek kaynak, üstten okla gezinme

Uygulamanın bütün gezinmesi tek bir enum üzerine kurulu: `AgendaPage` (`AgendaPage.swift`). Her case bir sayfa türünü temsil eder (`.cover`, `.calendar`, `.months(Date)`, `.day(Date)`, `.week(Date)`, `.month(Date)`, `.journal(Int)`). `ContentView` tek bir `@State private var page: AgendaPage` tutar ve `switch page` ile ilgili sayfa görünümünü kurar (`.id(page)` her sayfa değişiminde SwiftUI'a görünümü sıfırdan kurdurur).

Üstteki ok düğmeleri `page.previous` / `page.next` hesaplanan özelliklerini kullanır — bu ikisi ajandanın **tüm sayfa sırasını** tanımlar: kapak → yıllık takvim → aylar tablosu → günler (her ayın sonunda tekrar aylar tablosuna uğrar, bkz. `AgendaCalendar.repeatsMonthsTableAtMonthEnd`) → 30 boş günlük sayfası. Tarih aralığını ya da sayfa sırasını değiştirirken **yalnızca bu iki hesaplanan özelliği** güncellemek yeterli; sayfa sırası başka hiçbir yerde hardcode edilmemiştir. Değişiklikten sonra sırayı doğrulamanın basit yolu: bağımsız bir Swift betiğinde baştan sona `previous(next(x)) == x` kontrolü ve toplam sayfa/gün sayısını saymak.

Kenar çubuğundaki sekmelerin (`ContentView.SideRail`) hangisinin "aktif" göründüğü `AgendaPage.isCover` / `.isCalendar` / `.isDay` vb. yardımcılarıyla, bir sekmeye basınca hangi tarihe gidileceği ise `AgendaPage.anchorDate` ile belirlenir (kapak/takvim/günlükten "Ay" ya da "Hafta"ya geçilince bugüne gider; gün/hafta/ay sayfalarındaysa o sayfanın tarihine gider).

### Takvim hesapları: `AgendaCalendar` / `AgendaFormat`

Bütün tarih aritmetiği (`AgendaCalendar.swift`) tek yerde: başlangıç/bitiş tarihi, Türkçe/Pazartesi-başlangıçlı `Calendar`, hafta/ay sınırları, `journalPageCount`. Ekranlar `Calendar`'ı asla doğrudan kullanmaz, hep bu statik yardımcılardan geçer. Biçimlendirme (`"Ekim 2026"`, hafta aralığı metni vb.) `AgendaFormat` içinde, `DateFormatter`'lar `static let` olarak önbelleklenmiş.

### Veri katmanı: `NoteStore`

Tek `@Observable` sınıf; notları (`NoteID`: gün / günlük sayfa / günlük sayfanın elle yazılan tarihi) ve yapılacaklar listelerini (`TodoScope`: gün / hafta) `UserDefaults`'ta saklar (yapılacaklar JSON kodlanmış `[TodoItem]`, notlar düz metin). Açılışta `UserDefaults.dictionaryRepresentation()` taranıp önek eşleşen anahtarlar belleğe yüklenir — yeni bir not/yapılacak türü eklenirken bu tarama mantığına da eklemek gerekir. `hasContent(on:)` aylık ve yıllık takvim görünümündeki "bu günde içerik var" noktasını besler.

### Tema: kapak renginden türetilmiş palet

Kullanıcı kapaktan 12 hazır renkten birini seçer (`CoverPalette`, `CoverPageView.swift`). Bu tek renkten **bütün uygulamanın** açık/koyu tema paleti matematiksel olarak üretilir (`PaletteMath.swift` → `PaletteSpec.make(from:)`; saf HSB/RGB hesabı, ekrana/SwiftUI'a bağımlı değil, kontrast hedefine göre parlaklık ayarlar). `ThemeState.shared` seçili rengi `UserDefaults`'ta tutar, `AppPalette`'i renk kimliğine göre önbelleğe alır (`AppPalette.cached(for:)`). Ekranlar renklere hep `Theme.ink`, `Theme.accent` vb. statik hesaplanan özelliklerden erişir (`Theme.swift`) — bunlar arkada `ThemeState.shared.palette`'i okuduğundan **renk değişince her `Theme.x` çağıran görünüm SwiftUI tarafından otomatik yeniden çizilir**, ekstra bildirim gerekmez.

Yeni bir kapak rengi eklemek için: `CoverPalette.all`'a bir `CoverColor` ekle → `AppIconSwitcher`'ın kullandığı `AppIcon-<id>` adlı bir alternatif ikon setini `Assets.xcassets`'e ve `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` derleme ayarına ekle.

### Kilit ekranı: yerel, sunucusuz

`LockManager` (`@Observable`) üç durum yönetir: `.onboarding` (ilk kurulum), `.locked`, `.unlocked`. Şifre düz metin olarak hiçbir yerde tutulmaz; `PasscodeStore` (aynı dosyada) rastgele tuzla SHA-256 özetini Anahtar Zinciri'ne (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) yazar. `AppRootView`, `lock.state`'e göre `OnboardingView` / `LockScreenView` / `ContentView`'dan birini gösterir; kilitliyken ajandanın içeriği hiç kurulmaz. `scenePhase == .background` olunca `lock.lockIfNeeded()` çağrılır (uygulamadan her çıkışta yeniden kilitlenir). **Anahtar Zinciri işlemleri imzasız (`CODE_SIGNING_ALLOWED=NO`) derlemelerde sessizce başarısız olur** — kilit ekranını simülatörde denerken gerçek takım imzasıyla derlemek gerekir.

`PasscodeEntryView` hem kilit ekranında hem ilk kurulumda ortak kullanılan sayı tuş takımı bileşenidir. iPad gibi uzun ekranlarda `GeometryReader` + birden çok `Spacer`'ın dengesiz büyümesi tuş takımını ekranın dibine yapıştırabilir; bu yüzden ortadaki boşluk `maxHeight` ile sınırlanmış ve tuş takımının altına ayrıca bir `Spacer` eklenmiştir — başka bir ekrana benzer bir GeometryReader + çoklu Spacer deseni eklenirse aynı taşma riski (özellikle iPad'de) göz önünde bulundurulmalı.

### Çizgili kağıt: `LinedTextEditor`

Not alanları düz `TextEditor` değil, `UIViewRepresentable` ile sarılmış özel bir `UITextView` (`LinedUITextView`): TextKit 1 ile öngörülebilir satır yüksekliği için kurulmuş, arka planına metinle birlikte kayan çizgileri kendi `CAShapeLayer`'ıyla çizer. Yazı tipi/boyut/satır yüksekliği `LinedTextEditor` parametreleriyle ayarlanır.

### Sayfa görünümleri

Her sayfa türünün kendi dosyası var: `CoverPageView`, `YearCalendarView`, `MonthsIndexView`, `DayPageView`, `WeekPageView` (dar ekranda liste, `proxy.size.width >= 560` olunca iki sayfalık "açık ajanda" görünümü), `MonthPageView`, `JournalPageView`. Yapılacaklar listesi (`TodoListView`) gün sayfasında ve haftalık görünümün sonunda ortak kullanılır.
