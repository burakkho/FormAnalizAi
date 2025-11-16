# Form Analizi AI - Gemini Integration

## 🤖 Gemini AI Kullanımı

Form Analizi AI, Google'ın Gemini 2.0 Flash modelini kullanarak video analizi yapar. Bu döküman, Gemini API entegrasyonunun tüm detaylarını içerir.

## 📋 API Konfigürasyonu

### Model Seçimi
```swift
static let model = "gemini-2.0-flash-exp"
```

**Neden Gemini 2.0 Flash?**
- ✅ Video processing desteği
- ✅ Hızlı response time
- ✅ Cost-effective
- ✅ Yüksek kaliteli analiz

### API Endpoint
```
Base URL: https://generativelanguage.googleapis.com/v1beta
Endpoint: /models/{model}:generateContent
```

### Authentication
```swift
// Header
"Content-Type": "application/json"
"x-goog-api-key": "{YOUR_API_KEY}"
```

## 🔑 API Key Yönetimi

### Development (Debug)
```swift
// Configuration.swift
struct GeminiConfig {
    static var apiKey: String {
        #if DEBUG
        // Development key - Config.xcconfig'den oku
        return ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        #else
        // Production key - Info.plist'ten oku
        return Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
        #endif
    }
}
```

### Production
1. API Key'i Info.plist'e ekle
2. .gitignore'a ekle
3. CI/CD'de environment variable olarak inject et

**⚠️ GÜVENLİK UYARISI:**
- API Key'i asla source code'a hardcode etme
- Git'e commit etme
- Public repository'de paylaşma

## 📹 Video Upload Format

### Request Structure
```json
{
  "contents": [
    {
      "parts": [
        {
          "inline_data": {
            "mime_type": "video/mp4",
            "data": "{BASE64_ENCODED_VIDEO}"
          }
        },
        {
          "text": "{PROMPT}"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.4,
    "topK": 32,
    "topP": 1,
    "maxOutputTokens": 2048
  }
}
```

### Video Preparation
```swift
// Video'yu Base64'e çevir
func encodeVideoToBase64(_ videoData: Data) -> String {
    return videoData.base64EncodedString()
}
```

### Size Limits
- **Max video size**: 20 MB (Gemini limit)
- **Bizim optimize limit**: ~5-10 MB (720p, 30fps, 30sn)
- **Upload timeout**: 60 saniye

## 🎯 Prompt Engineering

### Prompt Yapısı

Her egzersiz için özel prompt template kullanılır. Prompt 3 bölümden oluşur:

1. **System Context**: AI'nın rolü ve görev tanımı
2. **Exercise Specific Criteria**: Egzersiz bazlı analiz kriterleri
3. **Output Format**: Beklenen yanıt formatı

### Base Prompt Template (Türkçe)

```
Sen profesyonel bir personal trainer ve form analiz uzmanısın. 
Kullanıcının {EGZERSIZ_ADI} egzersizi yaptığı videoyu analiz edeceksin.

ANALİZ KRİTERLERİ:
{EGZERSIZ_SPESIFIK_KRITERLER}

Videoyu dikkatle izle ve şu formatta analiz yap:

SKOR: [0-100 arası bir sayı]

GENEL DEĞERLENDİRME:
[2-3 cümlelik genel değerlendirme. Doğal ve samimi bir dille yaz, 
personal trainer gibi konuş. En önemli sorunu vurgula.]

DOĞRU YAPILANLAR:
- [Doğru yapılan nokta 1]
- [Doğru yapılan nokta 2]
- [Doğru yapılan nokta 3]

DÜZELTİLMESİ GEREKENLER:
- [Hata 1 - sakatlık riski varsa belirt]
- [Hata 2]
- [Hata 3]

ÖNERİLER:
- [Spesifik, uygulanabilir öneri 1]
- [Spesifik, uygulanabilir öneri 2]
- [Spesifik, uygulanabilir öneri 3]

ÖNEMLİ:
- Skor verirken gerçekçi ol
- Sakatlık riski olan hataları mutlaka belirt
- Önerilerin spesifik ve uygulanabilir olsun
- Professional ama samimi bir dil kullan
```

### Base Prompt Template (English)

```
You are a professional personal trainer and form analysis expert.
You will analyze the user's {EXERCISE_NAME} exercise video.

ANALYSIS CRITERIA:
{EXERCISE_SPECIFIC_CRITERIA}

Watch the video carefully and analyze in this format:

SCORE: [A number between 0-100]

GENERAL ASSESSMENT:
[2-3 sentence general assessment. Write in a natural and sincere tone,
speak like a personal trainer. Highlight the most important issue.]

CORRECT POINTS:
- [Correct point 1]
- [Correct point 2]
- [Correct point 3]

NEEDS CORRECTION:
- [Error 1 - mention if there's injury risk]
- [Error 2]
- [Error 3]

SUGGESTIONS:
- [Specific, actionable suggestion 1]
- [Specific, actionable suggestion 2]
- [Specific, actionable suggestion 3]

IMPORTANT:
- Be realistic when scoring
- Always mention errors with injury risk
- Make suggestions specific and actionable
- Use professional but friendly language
```

### Egzersiz Spesifik Kriterler

Detaylı prompt'lar için `EXERCISE_ANALYSIS_PROMPTS.md` dosyasına bakın.

**Örnek: Squat Kriterleri**
```
- Sırt pozisyonu (nötr spine, upper back tension)
- Diz hizası (ayak ucu hizası, içe/dışa kaçma)
- Kalça hareketi (hip hinge, depth)
- Ayak pozisyonu (stance width, toe angle)
- Bar path (dikey mi, sallanıyor mu)
- Tempo ve kontrol
```

## 📤 Request Implementation

### GeminiService.swift

```swift
import Foundation

actor GeminiService {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.0-flash-exp"
    private let apiKey = GeminiConfig.apiKey
    
    private let urlSession: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.urlSession = URLSession(configuration: config)
    }
    
    // Video analizi
    func analyzeVideo(
        _ videoData: Data, 
        exercise: Exercise, 
        language: String
    ) async throws -> AnalysisResponse {
        
        // 1. Video'yu base64'e çevir
        let base64Video = videoData.base64EncodedString()
        
        // 2. Prompt oluştur
        let prompt = generatePrompt(for: exercise, language: language)
        
        // 3. Request body oluştur
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "video/mp4",
                                "data": base64Video
                            ]
                        ],
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]
        
        // 4. Request oluştur
        var request = URLRequest(
            url: URL(string: "\(baseURL)/models/\(model):generateContent")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 5. Request gönder
        let (data, response) = try await urlSession.data(for: request)
        
        // 6. Response validate et
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 7. Parse et
        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        
        // 8. AnalysisResponse'a çevir
        return try parseAnalysisResponse(geminiResponse)
    }
    
    // Chat mesajı gönder
    func sendChatMessage(
        _ message: String,
        context: AnalysisResult,
        language: String
    ) async throws -> String {
        
        // Context: İlk analiz sonucunu text olarak ekle
        let contextPrompt = """
        Daha önce yaptığım analiz:
        Egzersiz: \(context.exercise.name)
        Skor: \(context.score)/100
        Genel Değerlendirme: \(context.generalFeedback)
        Doğru Yapılanlar: \(context.correctPoints.joined(separator: ", "))
        Hatalar: \(context.errors.joined(separator: ", "))
        Öneriler: \(context.suggestions.joined(separator: ", "))
        
        Kullanıcı sorusu: \(message)
        
        Kısa ve net cevap ver. Personal trainer gibi konuş.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contextPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]
        
        var request = URLRequest(
            url: URL(string: "\(baseURL)/models/\(model):generateContent")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GeminiError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
        
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }
        
        return text
    }
    
    // Prompt generator
    private func generatePrompt(for exercise: Exercise, language: String) -> String {
        // EXERCISE_ANALYSIS_PROMPTS.md'den oku
        // Bu dosya ayrı bir dokümanda detaylandırılacak
        return ExercisePrompts.getPrompt(for: exercise, language: language)
    }
    
    // Response parser
    private func parseAnalysisResponse(_ response: GeminiAPIResponse) throws -> AnalysisResponse {
        guard let text = response.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }
        
        // Text'i parse et
        return try AnalysisResponseParser.parse(text)
    }
}

// MARK: - Models

struct GeminiAPIResponse: Codable {
    let candidates: [Candidate]?
    
    struct Candidate: Codable {
        let content: Content?
        
        struct Content: Codable {
            let parts: [Part]?
            
            struct Part: Codable {
                let text: String?
            }
        }
    }
}

struct AnalysisResponse {
    let score: Int
    let generalFeedback: String
    let correctPoints: [String]
    let errors: [String]
    let suggestions: [String]
}

// MARK: - Parser

struct AnalysisResponseParser {
    static func parse(_ text: String) throws -> AnalysisResponse {
        // Regex veya string parsing ile alanları ayır
        
        // SKOR: 75 -> score
        let scorePattern = #"SKOR:\s*(\d+)"#
        guard let scoreMatch = text.range(of: scorePattern, options: .regularExpression),
              let score = Int(text[scoreMatch].components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") else {
            throw ParsingError.scoreNotFound
        }
        
        // GENEL DEĞERLENDİRME bölümünü çıkar
        let generalPattern = #"GENEL DEĞERLENDİRME:(.*?)(?=DOĞRU YAPILANLAR:|$)"#
        let generalFeedback = extractSection(from: text, pattern: generalPattern)
        
        // DOĞRU YAPILANLAR listesini çıkar
        let correctPattern = #"DOĞRU YAPILANLAR:(.*?)(?=DÜZELTİLMESİ GEREKENLER:|$)"#
        let correctPoints = extractListItems(from: text, pattern: correctPattern)
        
        // DÜZELTİLMESİ GEREKENLER listesini çıkar
        let errorsPattern = #"DÜZELTİLMESİ GEREKENLER:(.*?)(?=ÖNERİLER:|$)"#
        let errors = extractListItems(from: text, pattern: errorsPattern)
        
        // ÖNERİLER listesini çıkar
        let suggestionsPattern = #"ÖNERİLER:(.*?)(?=ÖNEMLİ:|$)"#
        let suggestions = extractListItems(from: text, pattern: suggestionsPattern)
        
        return AnalysisResponse(
            score: score,
            generalFeedback: generalFeedback,
            correctPoints: correctPoints,
            errors: errors,
            suggestions: suggestions
        )
    }
    
    private static func extractSection(from text: String, pattern: String) -> String {
        guard let range = text.range(of: pattern, options: .regularExpression) else {
            return ""
        }
        return String(text[range])
            .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func extractListItems(from text: String, pattern: String) -> [String] {
        let section = extractSection(from: text, pattern: pattern)
        return section
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("-") }
            .map { $0.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResponse
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Geçersiz API yanıtı"
        case .httpError(let code):
            return "HTTP Hatası: \(code)"
        case .emptyResponse:
            return "Boş yanıt alındı"
        case .apiKeyMissing:
            return "API anahtarı bulunamadı"
        }
    }
}

enum ParsingError: Error {
    case scoreNotFound
    case invalidFormat
}
```

## 📊 Rate Limiting & Cost

### API Limits (Free Tier)
- **Requests per minute**: 15
- **Requests per day**: 1,500
- **Tokens per minute**: 1 million

### Cost Estimation (Paid Tier)
- **Input**: $0.075 / 1M tokens
- **Output**: $0.30 / 1M tokens

**Örnek hesaplama:**
- Video upload: ~10,000 tokens
- Prompt: ~500 tokens
- Response: ~1,000 tokens
- **Toplam**: ~11,500 tokens per analiz
- **Maliyet**: ~$0.0011 per analiz

**Günlük 1000 kullanıcı x 3 analiz:**
- 3,000 analiz/gün
- ~$3.30/gün
- ~$100/ay

### Rate Limit Handling

```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 4 // 15 requests/min = 4 sn/request
    
    func waitIfNeeded() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                let waitTime = minimumInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}
```

## 🔄 Retry Logic

```swift
func analyzeVideoWithRetry(
    _ videoData: Data,
    exercise: Exercise,
    language: String,
    maxRetries: Int = 3
) async throws -> AnalysisResponse {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await analyzeVideo(videoData, exercise: exercise, language: language)
        } catch let error as GeminiError {
            lastError = error
            
            // Retry yapılabilir hatalar
            if case .httpError(let code) = error, code >= 500 {
                // Server error - retry
                let delay = Double(attempt + 1) * 2.0 // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
            
            // Retry yapılamaz hatalar
            throw error
        }
    }
    
    throw lastError ?? GeminiError.invalidResponse
}
```

## 🧪 Testing

### Mock Service

```swift
class MockGeminiService: GeminiServiceProtocol {
    var shouldFail = false
    var mockResponse: AnalysisResponse?
    
    func analyzeVideo(_ videoData: Data, exercise: Exercise, language: String) async throws -> AnalysisResponse {
        if shouldFail {
            throw GeminiError.httpError(statusCode: 500)
        }
        
        return mockResponse ?? AnalysisResponse(
            score: 75,
            generalFeedback: "Mock feedback",
            correctPoints: ["Point 1"],
            errors: ["Error 1"],
            suggestions: ["Suggestion 1"]
        )
    }
}
```

## 📝 Best Practices

1. **Error Handling**: Her API call try-catch içinde
2. **Timeout**: Makul timeout değerleri (60sn)
3. **Rate Limiting**: Free tier'da rate limit'e dikkat
4. **Retry Logic**: 5xx hatalarda retry
5. **Logging**: API calls ve errors logla (production'da analytics)
6. **Security**: API key'i güvenli sakla
7. **Testing**: Mock service kullan, gerçek API'ya bağımlı kalma

---

**Not**: Gemini API sürekli gelişiyor. Model versiyonlarını ve API değişikliklerini takip et.
