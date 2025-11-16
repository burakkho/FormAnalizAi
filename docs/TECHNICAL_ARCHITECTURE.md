# Form Analizi AI - Teknik Mimari

## 🏗️ Mimari Pattern: MVVM

Form Analizi AI projesi **MVVM (Model-View-ViewModel)** mimarisini kullanır. Swift 6.2 ve SwiftUI ile modern iOS geliştirme best practice'lerini takip eder.

## 📁 Proje Klasör Yapısı

```
FormAnaliziAI/
├── App/
│   ├── FormAnaliziAIApp.swift          # App entry point
│   └── ContentView.swift                # Root view
│
├── Models/
│   ├── Exercise.swift                   # Egzersiz model
│   ├── AnalysisResult.swift            # Analiz sonucu model
│   ├── ChatMessage.swift               # Chat mesaj model
│   ├── AnalysisSession.swift           # Analiz oturumu model
│   └── UserSubscription.swift          # Abonelik durumu model
│
├── ViewModels/
│   ├── HomeViewModel.swift             # Ana ekran logic
│   ├── ExerciseSelectionViewModel.swift # Egzersiz seçimi logic
│   ├── VideoRecordingViewModel.swift   # Kamera logic
│   ├── AnalysisViewModel.swift         # Analiz logic (AI işlemleri)
│   ├── ChatViewModel.swift             # Chat logic
│   ├── HistoryViewModel.swift          # Geçmiş logic
│   └── SubscriptionViewModel.swift     # Abonelik logic
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── Components/
│   │       ├── NewAnalysisButton.swift
│   │       └── HistoryButton.swift
│   │
│   ├── ExerciseSelection/
│   │   ├── ExerciseSelectionView.swift
│   │   └── Components/
│   │       ├── ExerciseCard.swift
│   │       └── ExerciseTipSheet.swift
│   │
│   ├── VideoCapture/
│   │   ├── VideoSourcePickerView.swift  # Kamera vs Galeri
│   │   ├── CameraView.swift
│   │   ├── VideoPickerView.swift
│   │   └── Components/
│   │       └── RecordButton.swift
│   │
│   ├── Analysis/
│   │   ├── AnalysisLoadingView.swift    # Progress gösterimi
│   │   ├── AnalysisResultView.swift     # Sonuç ekranı
│   │   └── Components/
│   │       ├── ScoreCard.swift
│   │       ├── CorrectItemsList.swift
│   │       ├── ErrorsList.swift
│   │       ├── SuggestionsList.swift
│   │       └── ChatButton.swift
│   │
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   └── Components/
│   │       ├── ChatBubble.swift
│   │       └── ChatInputField.swift
│   │
│   ├── History/
│   │   ├── HistoryView.swift
│   │   └── Components/
│   │       └── AnalysisHistoryCard.swift
│   │
│   ├── Subscription/
│   │   ├── PaywallView.swift
│   │   ├── PremiumFeaturesView.swift
│   │   └── Components/
│   │       └── SubscriptionPlanCard.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── HowToUseView.swift
│
├── Services/
│   ├── GeminiService.swift             # Gemini API entegrasyonu
│   ├── VideoProcessingService.swift    # Video optimize & process
│   ├── StorageService.swift            # Local storage (UserDefaults, FileManager)
│   ├── SubscriptionService.swift       # StoreKit 2 yönetimi
│   └── AnalyticsService.swift          # (Opsiyonel) Analytics tracking
│
├── Utilities/
│   ├── Constants.swift                  # App sabitleri
│   ├── Configuration.swift             # API keys, config
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── String+Extensions.swift
│   └── Helpers/
│       ├── VideoThumbnailGenerator.swift
│       └── DateFormatter.swift
│
├── Resources/
│   ├── Localizable.xcstrings           # String Catalog (TR + EN)
│   ├── Assets.xcassets/                # Images, colors, app icon
│   └── Info.plist
│
└── Tests/
    ├── UnitTests/
    │   ├── ViewModelTests/
    │   └── ServiceTests/
    └── UITests/
        └── FlowTests/
```

## 🔄 Data Flow (MVVM)

### 1. User Interaction Flow
```
View (SwiftUI)
    ↓ User Action (button tap, input)
ViewModel
    ↓ Business Logic
Service/Model
    ↓ Data Processing
ViewModel (State Update)
    ↓ @Published properties
View (UI Update - Automatic)
```

### 2. Örnek: Video Analizi Flow

```swift
// 1. User uploads video
VideoPickerView
    ↓ selected video URL
VideoRecordingViewModel.handleVideoSelection(url)
    ↓
VideoProcessingService.optimizeVideo(url)
    ↓ optimized video data
AnalysisViewModel.analyzeVideo(data, exercise)
    ↓
GeminiService.sendVideoToAPI(data, prompt)
    ↓ API response
AnalysisViewModel.parseResponse()
    ↓ update @Published analysisResult
AnalysisResultView automatically updates
```

## 📦 Models Detayı

### Exercise.swift
```swift
struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let nameEN: String
    let category: ExerciseCategory
    let requiresSlowMotion: Bool
    let cameraAngle: CameraAngle
    let tips: [String]
    
    enum ExerciseCategory: String, Codable {
        case compound
        case olympic
        case bodyweight
    }
    
    enum CameraAngle: String, Codable {
        case side       // Yan açı
        case front      // Ön açı
        case back       // Arka açı
    }
}
```

### AnalysisResult.swift
```swift
struct AnalysisResult: Identifiable, Codable {
    let id: UUID
    let exercise: Exercise
    let videoURL: URL
    let videoThumbnail: Data?
    let date: Date
    
    let score: Int                      // 0-100
    let generalFeedback: String         // Genel değerlendirme
    let correctPoints: [String]         // Doğru yapılanlar
    let errors: [String]                // Hatalar
    let suggestions: [String]           // Öneriler
    
    var chatMessages: [ChatMessage]     // Chat geçmişi
}
```

### ChatMessage.swift
```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}
```

### AnalysisSession.swift
```swift
struct AnalysisSession: Identifiable, Codable {
    let id: UUID
    let analysisResult: AnalysisResult
    var isActive: Bool
    let createdAt: Date
}
```

### UserSubscription.swift
```swift
struct UserSubscription: Codable {
    var isPremium: Bool
    var dailyAnalysisCount: Int
    var lastResetDate: Date
    var trialEndDate: Date?
    var subscriptionType: SubscriptionType?
    
    enum SubscriptionType: String, Codable {
        case monthly
        case yearly
    }
    
    var hasReachedDailyLimit: Bool {
        !isPremium && dailyAnalysisCount >= 3
    }
}
```

## 🎯 ViewModels Sorumlulukları

### HomeViewModel
- Ana ekran state yönetimi
- Daily limit kontrolü
- Navigation handling

### ExerciseSelectionViewModel
- Egzersiz listesi yönetimi
- Filtreleme (category'ye göre)
- Seçili egzersiz state

### VideoRecordingViewModel
- Kamera permission handling
- Video recording kontrolü
- Gallery picker yönetimi
- Video validation (süre, boyut, format)

### AnalysisViewModel (En Kritik)
```swift
@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var state: AnalysisState = .idle
    @Published var analysisResult: AnalysisResult?
    @Published var error: AnalysisError?
    
    private let geminiService: GeminiService
    private let videoProcessingService: VideoProcessingService
    private let storageService: StorageService
    
    enum AnalysisState {
        case idle
        case processingVideo
        case uploadingToAI
        case analyzingForm
        case completed
        case failed
    }
    
    func analyzeVideo(url: URL, exercise: Exercise) async {
        // 1. Video optimize
        // 2. Gemini API'ya gönder
        // 3. Response parse et
        // 4. AnalysisResult oluştur
        // 5. Storage'a kaydet
        // 6. Daily count artır
    }
}
```

### ChatViewModel
- Chat mesajları state yönetimi
- Gemini API ile text-only chat
- Message history

### HistoryViewModel
- Geçmiş analizleri storage'dan çek
- Liste state yönetimi
- Delete functionality

### SubscriptionViewModel
- StoreKit 2 entegrasyonu
- Purchase handling
- Restore purchases
- Subscription status tracking

## 🔧 Services Detayı

### GeminiService.swift

**Sorumluluklar:**
- Gemini API configuration
- Video upload to API
- Prompt generation (egzersiz bazlı)
- Response parsing
- Error handling

**Ana Methodlar:**
```swift
protocol GeminiServiceProtocol {
    func analyzeVideo(_ videoData: Data, exercise: Exercise, language: String) async throws -> AnalysisResponse
    func sendChatMessage(_ message: String, context: AnalysisResult, language: String) async throws -> String
}
```

**Configuration:**
```swift
// Configuration.swift içinde
struct GeminiConfig {
    static let apiKey: String = {
        // Config.plist'ten veya environment'tan oku
        // ASLA hardcode etme production'da
        return Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
    }()
    
    static let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    static let model = "gemini-2.0-flash-exp"
}
```

### VideoProcessingService.swift

**Sorumluluklar:**
- Video optimizasyonu (720p, 30fps)
- Süre kırpma (max 30sn)
- Compression
- Thumbnail generation

**Ana Methodlar:**
```swift
protocol VideoProcessingServiceProtocol {
    func optimizeVideo(_ url: URL) async throws -> Data
    func generateThumbnail(_ url: URL) async throws -> Data
    func validateVideo(_ url: URL) throws -> Bool
}
```

**Apple Best Practices:**
```swift
// AVAssetExportSession kullanımı
func optimizeVideo(_ url: URL) async throws -> Data {
    let asset = AVAsset(url: url)
    
    // 1. Süre kontrolü (max 30 saniye)
    let duration = try await asset.load(.duration)
    let timeRange = CMTimeRange(
        start: .zero,
        duration: min(duration, CMTime(seconds: 30, preferredTimescale: 600))
    )
    
    // 2. Export session oluştur
    guard let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPreset1280x720
    ) else {
        throw VideoError.exportFailed
    }
    
    // 3. Output settings
    exportSession.outputFileType = .mp4
    exportSession.timeRange = timeRange
    
    // 4. Export
    let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mp4")
    
    exportSession.outputURL = outputURL
    
    await exportSession.export()
    
    // 5. Data'ya çevir
    return try Data(contentsOf: outputURL)
}
```

### StorageService.swift

**Sorumluluklar:**
- AnalysisResult'ları disk'e kaydet
- Video'ları Documents directory'de sakla
- User subscription state
- Daily limit tracking

**Storage Stratejisi:**
```swift
// Videos
Documents/
    Videos/
        {uuid}.mp4
        
// Analysis Results (JSON)
Documents/
    Analyses/
        {uuid}.json
        
// User Data
UserDefaults:
    - subscription_status
    - daily_analysis_count
    - last_reset_date
```

### SubscriptionService.swift

**Sorumluluklar:**
- StoreKit 2 configuration
- Product loading
- Purchase handling
- Transaction validation
- Subscription status updates

**StoreKit 2 Implementation:**
```swift
import StoreKit

class SubscriptionService: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatus = .free
    
    private let monthlyProductID = "com.formanalizi.premium.monthly"
    private let yearlyProductID = "com.formanalizi.premium.yearly"
    
    func loadProducts() async throws -> [Product] {
        try await Product.products(for: [monthlyProductID, yearlyProductID])
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
}
```

## 🧵 Concurrency (Swift 6.2)

**Strict Concurrency ile Actor Usage:**

```swift
// GeminiService - Thread-safe API calls
actor GeminiService {
    private let urlSession: URLSession
    
    func analyzeVideo(_ videoData: Data, exercise: Exercise) async throws -> AnalysisResponse {
        // Thread-safe API call
    }
}

// ViewModels - Main Actor
@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var state: AnalysisState = .idle
    
    private let geminiService: GeminiService
    
    func analyzeVideo(url: URL, exercise: Exercise) async {
        state = .processingVideo
        
        // Background task
        let optimizedVideo = try await videoProcessingService.optimizeVideo(url)
        
        state = .uploadingToAI
        
        // API call (actor isolated)
        let result = try await geminiService.analyzeVideo(optimizedVideo, exercise: exercise)
        
        // UI update (main actor)
        state = .completed
        self.analysisResult = result
    }
}
```

## 🎨 SwiftUI State Management

**@StateObject vs @ObservedObject:**
```swift
// Root level - @StateObject
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
}

// Child views - @ObservedObject (passed down)
struct AnalysisResultView: View {
    @ObservedObject var viewModel: AnalysisViewModel
}
```

**Environment Objects:**
```swift
// App level shared state
@main
struct FormAnaliziAIApp: App {
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionViewModel)
        }
    }
}
```

## 🧪 Testing Stratejisi

### Unit Tests
- ViewModel logic tests
- Service tests (mock API)
- Model validation tests

### UI Tests
- Navigation flow tests
- Video upload flow
- Subscription flow

## 📊 Performance Considerations

1. **Video Processing**: Background thread'de yap
2. **Image Thumbnails**: Lazy loading kullan
3. **API Calls**: Proper timeout ve retry logic
4. **Memory**: Video data'yı kullandıktan sonra temizle
5. **Storage**: Eski analizleri periyodik temizle

## 🔐 Security Best Practices

1. **API Keys**: Info.plist'te sakla, Git'e commit etme
2. **Video Data**: Asla sunucuda saklama
3. **User Data**: UserDefaults encryption (hassas data için Keychain)
4. **Network**: HTTPS only, certificate pinning düşün

---

**Not**: Bu mimari MVP için tasarlanmıştır. Proje büyüdükçe modülerleştirme ve dependency injection pattern'leri eklenebilir.
