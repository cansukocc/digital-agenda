# Dijital Ajanda: Karşılaşılan Sorunlar ve Çözümler

Bu dosya, Dijital Ajanda uygulamasını geliştirirken (21–22 Eylül 2026) karşılaşılan sorunları, nedenlerini, nasıl çözüldüklerini ve çıkan dersleri anlatır.

---

## Özet tablo

| # | Sorun | Alan | Durum |
|---|---|---|---|
| 1 | Kilit ekranı simülatörde şifreyi kaydetmiyordu | Güvenlik / Anahtar Zinciri | ✅ Çözüldü |
| 2 | Uygulama arka plandan dönünce tekrar kilitlenmiyordu | Güvenlik / Yaşam döngüsü | ✅ Çözüldü |
| 3 | Çizgili yazı alanında çizgiler görünmüyordu | UIKit + SwiftUI | ✅ Çözüldü |
| 4 | Kartın gölgesi yazıları bulanıklaştırıyordu | Arayüz | ✅ Çözüldü |
| 5 | iPad'de şifre tuş takımı ekranın dibine kayıyordu | Responsive tasarım | ✅ Çözüldü |
| 6 | Kapak açılırken ekran kenarlarından taşıyordu | Animasyon | ✅ Çözüldü |
| 7 | Günlük sayfasında tarih alanına yazılamıyordu | Arayüz | ✅ Çözüldü |
| 8 | Tek renkten tüm uygulamanın temasını üretmek | Tasarım / Renk | ✅ Çözüldü |
| 9 | Ana ekran ikonunu kapak rengine göre değiştirmek | iOS kısıtı | ⚠️ Kısmen (iOS uyarısı gizlenemiyor) |
| 10 | Font denemesi beğenilmedi, geri alındı | Tasarım | ✅ Geri alındı |
| 11 | Mac dondu, komutlar çalışmaz oldu | Geliştirme ortamı | ✅ Yeniden başlatmayla çözüldü |
| 12 | Değişikliklerin çoğu commit edilmedi | Git / Sürüm kontrolü | ✅ Çözüldü |
| 13 | Projede otomatik test yok | Kalite | ❗ Açık |

---

## 1. Kilit ekranı simülatörde şifreyi kaydetmiyordu

**Belirti:** Şifre oluşturuluyor ama bir sonraki açılışta uygulama şifreyi hatırlamıyordu. Hata mesajı da çıkmıyordu.

**Neden:** Şifre, güvenli olsun diye iPhone'un **Anahtar Zinciri'nde (Keychain)** saklanıyor. Hızlı test için yapılan **imzasız derlemelerde** (`CODE_SIGNING_ALLOWED=NO`) Anahtar Zinciri işlemleri **sessizce başarısız oluyor**. Kod doğruydu ama derleme şekli yanlıştı.

**Çözüm:** Kilit ekranını denerken uygulamayı **geliştirici takımının imzasıyla** derlemek. Xcode'dan normal Run ile çalıştırınca sorun yok. Bu durum `CLAUDE.md`'ye not edildi.

**Ders:** Bir özellik "hiç hata vermeden çalışmıyorsa" sorun kodda değil ortamda olabilir. Güvenlikle ilgili iOS API'leri (Keychain, Face ID) imza ve yetki ister.

---

## 2. Uygulama arka plandan dönünce tekrar kilitlenmiyordu

**Belirti:** Doğru ve yanlış şifre çalışıyordu. Ama uygulamadan çıkıp geri dönünce ajanda **kilitsiz** açılıyordu. Bu bir **güvenlik açığıydı**.

**Neden:** Uygulamanın arka plana geçtiği an (sahne durumu, `scenePhase`) doğru yakalanmıyordu.

**Çözüm:** Sahne durumu günlüğe yazdırılıp incelendi. `scenePhase == .background` olduğunda `lock.lockIfNeeded()` çağrılacak şekilde düzenlendi. Ayrıca kilitliyken ajandanın içeriği hiç oluşturulmuyor. Böylece uygulama değiştiricide (app switcher) notlar görünmüyor.

**Ders:** Güvenlik özellikleri yalnızca "mutlu yol" ile değil, **uç durumlarla** da test edilmeli: arka plana gitmek, uygulamayı kapatmak, yeniden kurmak.

---

## 3. Çizgili yazı alanında çizgiler görünmüyordu

**Belirti:** Defter görünümü için yapılan çizgili not alanında çizgiler ekranda çıkmıyordu.

**Neden:** SwiftUI'ın hazır `TextEditor`'ı arka plana metinle birlikte kayan çizgi çizmeye izin vermiyor. Bu yüzden UIKit'in `UITextView`'ı SwiftUI içine gömüldü (`UIViewRepresentable`). Hata ayıklama sırasında görünümün başta **boyutunun sıfır** (`frame = 0`) olduğu ve henüz ekrana eklenmediği (`superview = nil`) görüldü. Çizgiler, görünüm boyutunu almadan önce çiziliyordu.

**Çözüm:** Özel bir `LinedUITextView` yazıldı. Öngörülebilir satır yüksekliği için TextKit 1 kullanıldı. Çizgiler kendi `CAShapeLayer`'ı ile, görünüm boyutunu aldıktan sonra ve metinle birlikte kayacak şekilde çiziliyor.

**Ders:** SwiftUI'ın hazır bileşenleri yetmediğinde UIKit'e inmek gerekebilir. O zaman da görünümün **yaşam döngüsünü** (ne zaman boyut alıyor, ne zaman ekrana ekleniyor) bilmek şart.

---

## 4. Kartın gölgesi yazıları bulanıklaştırıyordu

**Belirti:** Kartların içindeki yazılar bulanık görünüyordu.

**Neden:** SwiftUI'da `.shadow()` bir kapsayıcıya uygulanınca **içindeki her şeye**, yazılar dahil, ayrı ayrı gölge veriyor.

**Çözüm:** Gölge yalnızca kartın arka plan şekline uygulandı, içerik gölgeden ayrıldı.

**Ders:** SwiftUI'da değiştiricilerin (modifier) **hangi görünüme ve hangi sırayla** uygulandığı sonucu doğrudan etkiler.

---

## 5. iPad'de şifre tuş takımı ekranın dibine kayıyordu

**Belirti:** iPhone'da düzgün görünen şifre ekranında iPad'de tuş takımı ekranın en altına yapışıyordu.

**Neden:** `GeometryReader` ile birden fazla `Spacer` birlikte kullanılmıştı. iPad gibi uzun ekranlarda boşluklar **dengesiz büyüdü** ve tuş takımını aşağı itti.

**Çözüm:** Ortadaki boşluğa `maxHeight` sınırı konuldu, tuş takımının altına da ayrıca bir `Spacer` eklendi. Ardından küçük/büyük iPhone ve küçük/büyük iPad'de diğer ekranlar da benzer taşma sorunları için tarandı.

**Ders:** Uygulama **farklı ekran boyutlarında** test edilmeli. Tek bir simülatörde güzel görünmesi yetmez.

---

## 6. Kapak açılırken ekran kenarlarından taşıyordu

**Belirti:** Kapağı kaydırarak açma animasyonunda kapak 3D dönerken ekranın dışına taşıyordu.

**Neden:** 3D perspektif efekti fazla güçlüydü.

**Çözüm:** Perspektif azaltıldı. Yarım bırakılan kaydırmada kapağın geri kapanması sağlandı. VoiceOver kullananlar için ayrıca "Ajandayı aç" eylemi eklendi.

**Ders:** Etkileyici animasyonlar kullanılabilirliği bozmamalı. Erişilebilirlik (VoiceOver) de baştan düşünülmeli.

---

## 7. Günlük sayfasında tarih alanına yazılamıyordu

**Belirti:** Günlük (sabah sayfaları) bölümünde tarih kısmı yazılabilir değildi.

**Çözüm:** Tarih alanı yazılabilir yapıldı ve yanına bugünün tarihini tek dokunuşla yazan bir takvim düğmesi eklendi. Veri modeline (`NoteID`) "günlük sayfasının elle yazılan tarihi" türü eklendi.

**Ders:** Yeni bir veri türü eklenince **saklama katmanı** da güncellenmeli. `NoteStore` açılışta `UserDefaults`'u önek ile tarıyor, yeni türün bu taramaya da eklenmesi gerekiyor.

---

## 8. Tek renkten tüm uygulamanın temasını üretmek

**Zorluk:** Kullanıcının kapakta seçtiği **tek bir renkten** hem açık hem koyu tema için tüm uygulamanın paletini (zemin, kâğıt, yazı, vurgu rengi) üretmek. Üstelik yazıların her renkte **okunabilir** kalması gerekiyordu.

**Çözüm:** `PaletteMath.swift`'te HSB/RGB hesabıyla, **kontrast hedefine göre parlaklığı ayarlayan** bir palet üreticisi yazıldı. Paletler önbelleğe alınıyor. `Theme.x` üzerinden okunduğu için renk değişince bütün ekranlar kendiliğinden yeniden çiziliyor. 12 renk seçildi: 6 pastel ve 6 klasik koyu.

**Ders:** Tasarım kararlarını **matematiğe ve kurala** bağlamak, her renk için elle ayar yapmaktan çok daha ölçeklenebilir.

---

## 9. Ana ekran ikonunu kapak rengine göre değiştirmek

**Zorluk:** Kapak rengine göre uygulama ikonunun da değişmesi istendi.

**Çözüm:** Her renk için alternatif bir ikon seti (`AppIcon-<renk>`) oluşturuldu ve derleme ayarına (`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`) eklendi.

**Kısıt:** iOS, ikon her değiştiğinde **"simge değiştirildi" uyarısı** gösteriyor ve bu uyarı gizlenemiyor. İkon değişimi simülatörde görsel olarak doğrulanamadı, gerçek cihazda denenmeli.

**Ders:** Her istek teknik olarak mümkün olmayabilir. Platformun kısıtlarını erkenden öğrenip kullanıcı deneyimini buna göre tasarlamak gerekir.

---

## 10. Font denemesi beğenilmedi, geri alındı

**Durum:** Yazıların daha estetik görünmesi için font değiştirildi ama sonuç beğenilmedi ve eski fonta dönüldü.

**Ders:** Tasarım değişikliklerini küçük adımlarla yapmak ve her adımı **commit etmek**, geri dönüşü kolaylaştırır.

---

## 11. Mac dondu, komutlar çalışmaz oldu

**Belirti:** Farklı cihazlarda responsive test yapılırken en basit terminal komutu bile `fork failed: resource temporarily unavailable` hatası verdi, ardından Mac tamamen dondu.

**Neden:** Aynı anda çok sayıda simülatör ve derleme süreci çalıştığı için sistem kaynakları (süreç sınırı ve bellek) tükendi.

**Çözüm:** Mac yeniden başlatıldı. Yarım kalan hata ayıklama kodları (`TEMP-DEBUG` blokları) temizlendi.

**Ders:** Kullanılmayan simülatörleri kapatmak gerekir (`xcrun simctl shutdown all`). Aynı anda çok sayıda cihazda test ederken Etkinlik İzleyici'den kaynaklar takip edilmeli.

---

## 12. Değişikliklerin çoğu commit edilmedi ✅

**Durum (o sırada):** Git geçmişinde yalnızca 2 commit vardı. Sonrasında eklenen kapak, yıllık takvim, tema sistemi, kilit ekranı, yapılacaklar listesi ve alternatif ikonlar gibi özellikler günlerce commit edilmeden çalışma dizininde bekledi.

**Risk:** Bir hata ya da yanlış bir değişiklik olursa bu işin tamamı geri alınamayabilirdi.

**Çözüm:** Değişiklikler anlamlı parçalara bölünüp commit edildi, `.gitignore` eklendi (kullanıcıya özel Xcode dosyaları temizlendi) ve proje GitHub'a public olarak yüklendi.

**Ders:** Büyük bir özellik grubunu tek seferde bitirip sona bırakmak yerine, her özellik bittiğinde commit atmak hem geri almayı kolaylaştırır hem de "bir şey bozulursa her şeyi kaybederim" kaygısını ortadan kaldırır.

---

## 13. Projede otomatik test yok ❗

**Durum:** Projede XCTest hedefi yok. Doğrulama derleme ve simülatörde ekran görüntüsüyle elle yapılıyor. Sayfa sırası ve şifre mantığı geçici betiklerle sınandı ama bu testler projede kalmadı.

**Yapılması gereken:** En azından şunlar için birim testleri eklenmeli:
- Sayfa sırası: `previous(next(x)) == x` ve toplam gün sayısı
- Şifre mantığı: kaydetme, doğrulama, 5 yanlıştan sonra bekleme, sıfırlama
- Palet üretimi: her renk için kontrast oranı eşiğin üstünde mi

---

## Genel dersler

1. **Ortamı da şüpheli listesine al:** İmza, simülatör ve sistem kaynakları koddan bağımsız sorun çıkarabilir.
2. **Birden çok cihazda test et:** iPhone ve iPad arasındaki fark tasarımı bozabilir.
3. **Güvenlikte uç durumları dene:** Arka plan, yeniden kurulum, yanlış şifre denemeleri.
4. **SwiftUI yetmezse UIKit'e in:** Ama görünüm yaşam döngüsünü iyi anla.
5. **Sık ve küçük commit at:** Geri almak ve ne değiştiğini görmek kolaylaşır.
6. **Kararları belgele:** `CLAUDE.md` ve bu dosya gibi notlar, sonraki geliştirmede aynı tuzaklara düşmeyi önler.

---

## Kendi notların

> Bu bölümü sen doldurabilirsin: Kod dışında zorlandığın şeyler (Xcode'u öğrenmek, cihaza yükleme, tasarım kararları vermek vb.)

- 
