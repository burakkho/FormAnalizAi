# Form Analizi AI - Proje Genel Bakış

## 📱 Proje Tanımı

Form Analizi AI, kullanıcıların egzersiz videolarını yükleyerek yapay zeka destekli form analizi yapabilecekleri bir iOS uygulamasıdır. Gemini AI kullanarak video analizi yapılır ve kullanıcıya detaylı geri bildirim verilir.

## 🎯 Hedef Kitle

- Fitness salonlarına giden sporcular
- Evde antrenman yapan bireyler
- Form konusunda geri bildirim almak isteyen kişiler
- Sakatlık riskini azaltmak isteyenler
- Personal trainer desteği almak isteyen kullanıcılar

## ✨ Temel Özellikler

### MVP Özellikleri

1. **Video Yükleme**
   - Kameradan direkt video çekimi
   - Galeriden video seçimi
   - Video optimizasyonu (720p, 30fps, max 30sn)

2. **Egzersiz Seçimi**
   - 11 temel egzersiz
   - Her egzersiz için özel analiz kriterleri
   - Olympic lifts için slow-motion önerisi

3. **AI Form Analizi**
   - Gemini Vision API entegrasyonu
   - Otomatik detaylı analiz raporu
   - 0-100 form skoru
   - Hatalar, riskler ve öneriler

4. **Conversational Chat**
   - Analiz sonrası soru-cevap
   - Detaylı açıklamalar
   - Natural language processing

5. **Geçmiş Takibi**
   - Tüm analizler cihazda saklanır
   - Video thumbnail ile görsel liste
   - Tarih ve skor bilgisi

6. **Freemium Model**
   - Ücretsiz: 3 analiz/gün
   - Premium: Sınırsız analiz
   - 7 gün ücretsiz deneme
   - 2 USD/ay veya 20 USD/yıl

## 🏋️ Desteklenen Egzersizler

### Compound Hareketler (7)
1. Squat
2. Front Squat
3. Deadlift
4. Romanian Deadlift
5. Bench Press
6. Overhead Press
7. Barbell Row

### Olympic Lifts (2)
8. Clean & Jerk
9. Snatch

### Bodyweight (2)
10. Push-up
11. Pull-up

## 🎨 Tasarım Prensibleri

- **Minimalist**: Siyah-beyaz renk paleti
- **Kullanıcı Odaklı**: Basit ve anlaşılır arayüz
- **Profesyonel**: Premium hissiyat
- **Apple HIG Uyumlu**: iOS tasarım standartları

## 🌍 Dil Desteği

- Türkçe (varsayılan)
- İngilizce
- String Catalog ile yönetim
- AI otomatik dil algılama

## 📊 Kullanıcı Akışı

### Ana Akış
```
Uygulama Açılış
    ↓
Ana Ekran
    ↓
Yeni Analiz Butonu
    ↓
Egzersiz Seçimi
    ↓
Video Kaynağı Seçimi (Kamera / Galeri)
    ↓
Video Çekimi/Seçimi
    ↓
Video Optimizasyonu (Loading)
    ↓
AI Analizi (Loading - Adımlı Progress)
    ↓
Analiz Sonucu
    ├─→ Skor (0-100)
    ├─→ Doğru yapılanlar
    ├─→ Hatalar
    ├─→ Öneriler
    └─→ Chat Butonu
         ↓
    Soru-Cevap (Opsiyonel)
```

### Limit Dolduğunda
```
3. Analiz Tamamlandı
    ↓
Limit Uyarısı Modal
    ├─→ Premium'a Geç (7 gün ücretsiz)
    └─→ Yarın Tekrar Dene
```

## 🔒 Privacy & Güvenlik

- **Videolar cihazda saklanır** (sunucuya yüklenmez)
- Sadece analiz için Gemini API'ya gönderilir
- Apple Privacy standartlarına uygunluk
- Gizlilik politikası ayarlarda erişilebilir

## 💰 Monetizasyon

### Ücretsiz Kullanıcı
- Günlük 3 analiz
- Tüm egzersizler
- Chat özelliği
- Geçmiş görüntüleme

### Premium Kullanıcı
- Sınırsız analiz
- 7 gün ücretsiz deneme
- Aylık: 2 USD
- Yıllık: 20 USD (%17 indirim)
- StoreKit 2 ile yönetim

## 📱 Teknik Özellikler

- **Platform**: iOS 17.0+
- **Dil**: Swift 6.2
- **Mimari**: MVVM Pattern
- **AI**: Gemini Vision API
- **Abonelik**: StoreKit 2
- **Video**: AVFoundation
- **Localization**: String Catalog

## 🚀 Proje Hedefleri

### Kısa Vadeli (MVP)
- ✅ Core video analiz sistemi
- ✅ 11 egzersiz desteği
- ✅ Freemium model
- ✅ Türkçe + İngilizce

### Orta Vadeli
- Egzersiz sayısı artırma
- İlerleme grafikleri
- Video karşılaştırma
- Push notification hatırlatıcılar

### Uzun Vadeli
- Sosyal özellikler (paylaşım)
- Personal trainer marketplace
- Özel antrenman programları
- Apple Watch entegrasyonu

## 📈 Başarı Metrikleri

- Günlük aktif kullanıcı sayısı
- Free to Premium conversion rate
- Kullanıcı başına ortalama analiz sayısı
- Premium kullanıcı retention rate
- App Store rating
- Kullanıcı geri bildirimleri

## 🎯 Diferansiyatörler

1. **AI Destekli Personal Trainer**: 7/24 erişilebilir form koçu
2. **Türkçe Destek**: Türkiye pazarında ilk
3. **Conversational AI**: Sadece rapor değil, soru-cevap
4. **Olympic Lifts**: Profesyonel ağırlık kaldırma desteği
5. **Privacy First**: Tüm veriler cihazda
6. **Uygun Fiyat**: Ayda sadece 2 USD

---

**Not**: Bu döküman MVP (Minimum Viable Product) için hazırlanmıştır. Gelişim sürecinde özellikler eklenebilir veya değiştirilebilir.
