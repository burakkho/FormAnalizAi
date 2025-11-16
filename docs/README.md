# Form Analizi AI - Döküman Paketi

Bu klasör, **Form Analizi AI** iOS uygulamasının tam teknik dökümanlarını içerir. Claude Code ile geliştirme yapmak için hazırlanmıştır.

## 📚 Döküman Listesi

### 1. 📋 PROJECT_OVERVIEW.md
**Ne içerir:**
- Proje tanımı ve hedefler
- Hedef kitle
- Temel özellikler listesi
- Desteklenen egzersizler (11 adet)
- Kullanıcı akışı diyagramları
- Monetizasyon modeli
- Başarı metrikleri

**Ne zaman kullanılır:** Projeyi anlamak, genel bakış için

---

### 2. 🏗️ TECHNICAL_ARCHITECTURE.md
**Ne içerir:**
- MVVM mimari pattern detayları
- Klasör yapısı (tam organizasyon)
- Model tanımları (Exercise, AnalysisResult, vb.)
- ViewModel sorumlulukları
- Service layer detayları
- Data flow diyagramları
- Swift 6.2 concurrency kullanımı
- Testing stratejisi

**Ne zaman kullanılır:** Kod yazmaya başlamadan önce, mimariyi anlamak için

---

### 3. 🤖 GEMINI_INTEGRATION.md
**Ne içerir:**
- Gemini AI API konfigürasyonu
- Video upload formatı
- Request/Response yapıları
- Error handling
- Rate limiting
- Cost estimation
- Retry logic
- Mock service örnekleri

**Ne zaman kullanılır:** AI entegrasyonu yaparken, API çağrıları için

---

### 4. 🏋️ EXERCISE_ANALYSIS_PROMPTS.md
**Ne içerir:**
- 11 egzersiz için detaylı AI prompt'ları
- Her egzersiz için analiz kriterleri
- Sakatlık riski kontrolleri
- Türkçe + İngilizce versiyonlar
- Prompt template yapısı
- Skor hesaplama formatı

**Ne zaman kullanılır:** Gemini AI'ya gönderilecek prompt'ları yazmak için

---

### 5. 🎨 UI_SPECIFICATIONS.md
**Ne içerir:**
- Design system (renkler, typography, spacing)
- Her ekran için wireframe'ler
- SwiftUI kod snippet'leri
- Component library
- Button styles
- Layout guidelines
- Accessibility notları

**Ne zaman kullanılır:** UI kodları yazarken, tasarım kararları için

---

### 6. 🎥 VIDEO_PROCESSING.md
**Ne içerir:**
- Video optimize stratejisi
- AVFoundation kullanımı
- Kamera implementasyonu
- Gallery picker
- Thumbnail generation
- Performance optimizations
- Permission handling

**Ne zaman kullanılır:** Video işleme kodlarını yazarken

---

### 7. 💎 SUBSCRIPTION_SYSTEM.md
**Ne içerir:**
- StoreKit 2 implementasyonu
- Abonelik modeli (aylık/yıllık)
- Freemium limitleri
- Purchase flow
- Restore purchases
- Paywall UI
- Analytics tracking

**Ne zaman kullanılır:** Abonelik sistemini kurarken

---

### 8. 🗺️ DEVELOPMENT_ROADMAP.md
**Ne içerir:**
- Adım adım geliştirme planı (Phase 1-8)
- Timeline estimateleri
- MVP feature list
- Testing checklist
- Launch checklist
- Risk management
- Success metrics

**Ne zaman kullanılır:** Geliştirmeye başlarken, hangi sırayla ne yapılacak

---

### 9. 🌐 GITHUB_PAGES.md
**Ne içerir:**
- `gh-pages/` klasöründeki landing page yapısı
- GitHub Pages'i main veya `gh-pages` branch'inden yayına alma adımları
- İçeriği güncellerken dikkat edilmesi gerekenler

**Ne zaman kullanılır:** Proje için tanıtım sitesi / dokümantasyon splash sayfası oluştururken

---

## 🚀 Hızlı Başlangıç

### Claude Code ile Çalışma

1. **Önce Oku:**
   - `PROJECT_OVERVIEW.md` - Projeyi anla
   - `DEVELOPMENT_ROADMAP.md` - Ne yapacağını öğren

2. **Sonra Referans Olarak Kullan:**
   - `TECHNICAL_ARCHITECTURE.md` - Kod yazarken
   - Diğer dökümanlar - İhtiyaç oldukça

3. **Geliştirme Sırası:**
   ```
   Phase 1: Setup → Phase 2: Models → Phase 3: Services
   → Phase 4: Components → Phase 5: Views → Phase 6: Testing
   → Phase 7: Polish → Phase 8: App Store
   ```

### Önemli Notlar

#### ⚙️ Konfigürasyon
- **API Key:** Gemini API key'ini `Info.plist`'te sakla
- **Bundle ID:** `com.yourname.formanalizi` olarak değiştir
- **Team ID:** Apple Developer hesabını bağla

#### 🔑 Gereksinimler
- Xcode 15.0+
- Swift 6.2
- iOS 17.0+
- Apple Developer Program (subscription için)
- Gemini API key

#### 📦 Bağımlılıklar
**Hiç external dependency yok!** Sadece native iOS framework'leri:
- SwiftUI
- AVFoundation
- StoreKit 2
- PhotosUI

## 📂 Proje Klasör Yapısı (Özet)

```
FormAnaliziAI/
├── App/                         # App entry point
├── Models/                      # Data models
├── Views/                       # SwiftUI views
│   ├── Home/
│   ├── ExerciseSelection/
│   ├── VideoCapture/
│   ├── Analysis/
│   ├── Chat/
│   ├── History/
│   ├── Subscription/
│   └── Settings/
├── ViewModels/                  # Business logic
├── Services/                    # API, Storage, Video processing
├── Utilities/                   # Helpers, extensions
└── Resources/                   # Assets, localization
```

## 🎯 MVP Özellikleri

### ✅ Temel Özellikler
- [x] 11 egzersiz desteği
- [x] Video çekimi/galeriden seçim
- [x] AI form analizi (Gemini)
- [x] Chat ile soru-cevap
- [x] Analiz geçmişi
- [x] Freemium (3 analiz/gün)
- [x] Premium abonelik
- [x] Türkçe + İngilizce

### 🔜 Sonraki Versiyon
- Progress grafikleri
- Video karşılaştırma
- PDF export
- Dark mode

## 💡 Development Tips

### ✅ Do's
- ✅ Her adımı test et
- ✅ MVVM pattern'i takip et
- ✅ Error handling yap
- ✅ String Catalog kullan (localization için)
- ✅ Apple HIG'a uy
- ✅ Background thread'lerde işle
- ✅ Memory management'a dikkat et

### ❌ Don'ts
- ❌ API key'i hardcode etme
- ❌ Main thread'i blokla
- ❌ Error'ları ignore etme
- ❌ String'leri hardcode etme
- ❌ Async/await'i yanlış kullanma
- ❌ Memory leak'leri göz ardı etme

## 📊 Teknik Özellikler

| Özellik | Detay |
|---------|-------|
| **Platform** | iOS 17.0+ |
| **Dil** | Swift 6.2 |
| **UI Framework** | SwiftUI |
| **Mimari** | MVVM |
| **AI** | Gemini 2.0 Flash |
| **Video** | AVFoundation |
| **Subscription** | StoreKit 2 |
| **Localization** | String Catalog |

## 🧪 Testing

### Unit Tests
- VideoProcessingService
- GeminiService (mock)
- SubscriptionService
- AnalysisResponseParser

### UI Tests
- Ana flow (Home → Analysis)
- Subscription flow
- History navigation

### Manual Testing
- iPhone SE (küçük ekran)
- iPhone 15 Pro (standart)
- iPhone 15 Pro Max (büyük)
- iOS 17.0 ve 18.0

## 📱 App Store

### Gerekli Sayfalar
- **Privacy Policy:** https://yoursite.com/privacy (gerekli!)
- **Terms of Service:** https://yoursite.com/terms

### Subscription Setup
1. App Store Connect'te subscription group oluştur
2. Monthly product ekle ($1.99)
3. Yearly product ekle ($19.99)
4. Localization'ları tamamla

## 🎨 Branding

- **Renk:** Siyah-Beyaz minimal
- **İkon:** Basit, minimalist
- **Stil:** Professional, modern

## 🔒 Privacy

### Info.plist Permissions
```xml
NSCameraUsageDescription
NSMicrophoneUsageDescription
NSPhotoLibraryUsageDescription
```

### Veri Saklama
- **Videolar:** Cihazda (Documents/)
- **Analizler:** Cihazda (JSON)
- **Subscription:** UserDefaults
- **API:** Sadece analiz için

## 📞 Destek

Bu dökümanlar hakkında sorularınız varsa:
1. İlgili dökümana tekrar bakın
2. DEVELOPMENT_ROADMAP.md'deki adımları kontrol edin
3. Apple documentation'a bakın
4. Stack Overflow'da arayın

## 🏆 Success Metrics

### Teknik
- Build time < 30s
- App size < 50 MB
- Video processing < 10s
- Analysis < 15s

### Business
- Trial conversion > 30%
- Day 7 retention > 40%
- Rating > 4.5⭐

---

## 📝 Son Notlar

Bu dökümanlar, **Claude Code** ile çalışmak için optimize edilmiştir. Her döküman:
- ✅ Detaylı
- ✅ Pratik kod örnekleri içerir
- ✅ Best practice'leri gösterir
- ✅ Test edilebilir
- ✅ Incrementally geliştirilebilir

**Başarılar!** 🚀

Personal trainer + developer kombinasyonunla harika bir uygulama çıkacak! 💪

---

**Versiyon:** 1.0  
**Son Güncelleme:** 15 Kasım 2025  
**Proje:** Form Analizi AI MVP
