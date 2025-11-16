# Form Analizi AI - UI Specifications

## 🎨 Design System

### Color Palette (Siyah-Beyaz Minimal)

```swift
// Colors.swift
extension Color {
    // Primary Colors
    static let primaryBlack = Color(hex: "#000000")
    static let primaryWhite = Color(hex: "#FFFFFF")
    
    // Grays
    static let gray900 = Color(hex: "#111111")  // Çok koyu
    static let gray800 = Color(hex: "#1E1E1E")
    static let gray700 = Color(hex: "#2D2D2D")
    static let gray600 = Color(hex: "#3D3D3D")
    static let gray500 = Color(hex: "#6B6B6B")
    static let gray400 = Color(hex: "#9B9B9B")
    static let gray300 = Color(hex: "#C4C4C4")
    static let gray200 = Color(hex: "#E5E5E5")
    static let gray100 = Color(hex: "#F5F5F5")
    
    // Semantic Colors
    static let success = Color(hex: "#10B981")     // Yeşil - doğru yapılanlar
    static let warning = Color(hex: "#F59E0B")     // Turuncu - uyarılar
    static let error = Color(hex: "#EF4444")       // Kırmızı - hatalar
    static let info = Color(hex: "#3B82F6")        // Mavi - bilgi
    
    // Background
    static let background = Color.primaryWhite
    static let backgroundSecondary = Color.gray100
    static let backgroundCard = Color.primaryWhite
    
    // Text
    static let textPrimary = Color.primaryBlack
    static let textSecondary = Color.gray600
    static let textTertiary = Color.gray400
}

// Helper extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### Typography

```swift
// Typography.swift
extension Font {
    // Display (Headings)
    static let displayLarge = Font.system(size: 34, weight: .bold)      // Ana başlıklar
    static let displayMedium = Font.system(size: 28, weight: .semibold) // Section başlıklar
    static let displaySmall = Font.system(size: 24, weight: .semibold)
    
    // Title
    static let titleLarge = Font.system(size: 22, weight: .medium)
    static let titleMedium = Font.system(size: 18, weight: .medium)
    static let titleSmall = Font.system(size: 16, weight: .medium)
    
    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    
    // Label
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
    
    // Caption
    static let caption = Font.system(size: 12, weight: .regular)
}
```

### Spacing

```swift
// Spacing.swift
struct Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Corner Radius

```swift
struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}
```

## 📱 Screen Specifications

### 1. Home View (Ana Ekran)

**Wireframe:**
```
┌────────────────────────────────┐
│   ← Back                    ℹ️  │ ← Navigation Bar
├────────────────────────────────┤
│                                │
│     FORM ANALİZİ AI           │ ← Display Large, Bold
│                                │
│                                │
│   ┌────────────────────────┐   │
│   │                        │   │
│   │   [Minimalist Icon]    │   │ ← Placeholder için icon
│   │   Workout illustration │   │    (dumbbell, form silhouette)
│   │                        │   │
│   └────────────────────────┘   │
│                                │
│   Egzersiz formunu analiz et,  │ ← Body Medium, Gray600
│   hatalarını bul, sakatlıkları │
│   önle.                        │
│                                │
│   ┌────────────────────────┐   │
│   │     📹 Yeni Analiz     │   │ ← Primary Button
│   └────────────────────────┘   │    (Black bg, White text)
│                                │
│   ┌────────────────────────┐   │
│   │     📂 Geçmiş         │   │ ← Secondary Button
│   └────────────────────────┘   │    (White bg, Black border)
│                                │
│                                │
│        ℹ️ Nasıl Kullanılır      │ ← Text Button (Gray)
│                                │
└────────────────────────────────┘
```

**Kod Snippet:**
```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showHowToUse = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Title
                Text("FORM ANALİZİ AI")
                    .font(.displayLarge)
                    .foregroundColor(.textPrimary)
                
                // Icon/Illustration
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 80))
                    .foregroundColor(.gray800)
                    .padding(.vertical, Spacing.lg)
                
                // Description
                Text("Egzersiz formunu analiz et, hatalarını bul, sakatlıkları önle.")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                
                Spacer()
                
                // Primary Button - New Analysis
                NavigationLink(destination: ExerciseSelectionView()) {
                    HStack {
                        Image(systemName: "video.fill")
                        Text("Yeni Analiz")
                            .font(.titleMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.primaryBlack)
                    .foregroundColor(.primaryWhite)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.lg)
                
                // Secondary Button - History
                NavigationLink(destination: HistoryView()) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Geçmiş")
                            .font(.titleMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.primaryWhite)
                    .foregroundColor(.primaryBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.gray300, lineWidth: 1)
                    )
                }
                .padding(.horizontal, Spacing.lg)
                
                // How to Use Button
                Button {
                    showHowToUse = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Nasıl Kullanılır")
                    }
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                }
                .padding(.bottom, Spacing.lg)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showHowToUse) {
                HowToUseView()
            }
        }
    }
}
```

### 2. Exercise Selection View

**Wireframe:**
```
┌────────────────────────────────┐
│   ← Geri      Egzersiz Seç     │
├────────────────────────────────┤
│                                │
│   Compound Hareketler          │ ← Section Header
│   ┌────────────────────────┐   │
│   │  🏋️  Squat            >  │   │ ← Exercise Card
│   └────────────────────────┘   │
│   ┌────────────────────────┐   │
│   │  🏋️  Deadlift         >  │   │
│   └────────────────────────┘   │
│   ┌────────────────────────┐   │
│   │  🏋️  Bench Press      >  │   │
│   └────────────────────────┘   │
│                                │
│   Olympic Lifts                │
│   ┌────────────────────────┐   │
│   │  🏋️  Clean & Jerk    >  │   │
│   │  ⚠️ Slow-motion önerilir│   │ ← Uyarı badge
│   └────────────────────────┘   │
│                                │
│   Bodyweight                   │
│   ┌────────────────────────┐   │
│   │  💪  Push-up          >  │   │
│   └────────────────────────┘   │
│                                │
└────────────────────────────────┘
```

**Kod Snippet:**
```swift
struct ExerciseSelectionView: View {
    @StateObject private var viewModel = ExerciseSelectionViewModel()
    
    var body: some View {
        List {
            // Compound Hareketler
            Section(header: Text("Compound Hareketler")) {
                ForEach(viewModel.compoundExercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            }
            
            // Olympic Lifts
            Section(header: Text("Olympic Lifts")) {
                ForEach(viewModel.olympicExercises) { exercise in
                    ExerciseRow(exercise: exercise, showSlowMotionTip: true)
                }
            }
            
            // Bodyweight
            Section(header: Text("Bodyweight")) {
                ForEach(viewModel.bodyweightExercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            }
        }
        .navigationTitle("Egzersiz Seç")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    var showSlowMotionTip: Bool = false
    @State private var showTip = false
    
    var body: some View {
        NavigationLink(destination: VideoSourcePickerView(exercise: exercise)) {
            HStack {
                Text(exercise.icon)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                    
                    if showSlowMotionTip {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("Slow-motion önerilir")
                                .font(.caption)
                        }
                        .foregroundColor(.warning)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray400)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
            .onTapGesture {
                if showSlowMotionTip {
                    showTip = true
                }
            }
        }
        .sheet(isPresented: $showTip) {
            SlowMotionTipSheet(exercise: exercise)
        }
    }
}
```

### 3. Analysis Result View

**Wireframe:**
```
┌────────────────────────────────┐
│   ✕                            │
├────────────────────────────────┤
│                                │
│   ┌────────────────────────┐   │
│   │                        │   │
│   │   [Video Thumbnail]    │   │ ← Tıklanabilir video
│   │        ▶️               │   │
│   │                        │   │
│   └────────────────────────┘   │
│                                │
│   ┌────────────────────────┐   │
│   │       75/100           │   │ ← Skor kartı
│   │     ━━━━━━━━━━         │   │    (Progress bar)
│   └────────────────────────┘   │
│                                │
│   GENEL DEĞERLENDİRME         │ ← Section
│   ┌────────────────────────┐   │
│   │ Formun genel olarak    │   │
│   │ iyi, ama dizlerin...   │   │ ← Body text, multi-line
│   └────────────────────────┘   │
│                                │
│   ✅ DOĞRU YAPILANLAR         │
│   • Sırt düz ve nötr          │
│   • Başlangıç pozisyonu doğru │
│                                │
│   ❌ DÜZELTİLMESİ GEREKENLER  │
│   • Dizler ayak ucunu geçiyor │
│   • Kalça yeterince geriye... │
│                                │
│   💡 ÖNERİLER                 │
│   • Ağırlığı %20 azalt        │
│   • Kalçayı sandalyeye...     │
│                                │
│   ┌────────────────────────┐   │
│   │   💬 Soru Sor          │   │ ← Chat butonu
│   └────────────────────────┘   │
│                                │
└────────────────────────────────┘
```

**Kod Snippet:**
```swift
struct AnalysisResultView: View {
    let analysisResult: AnalysisResult
    @State private var showChat = false
    @State private var showVideoPlayer = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Video Thumbnail
                Button {
                    showVideoPlayer = true
                } label: {
                    ZStack {
                        AsyncImage(url: analysisResult.videoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray200)
                        }
                        .frame(height: 200)
                        .cornerRadius(CornerRadius.md)
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryWhite)
                    }
                }
                .padding(.horizontal, Spacing.md)
                
                // Score Card
                ScoreCard(score: analysisResult.score)
                    .padding(.horizontal, Spacing.md)
                
                // General Assessment
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("GENEL DEĞERLENDİRME")
                        .font(.labelLarge)
                        .foregroundColor(.textSecondary)
                    
                    Text(analysisResult.generalFeedback)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                        .padding(Spacing.md)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.sm)
                }
                .padding(.horizontal, Spacing.md)
                
                // Correct Points
                AnalysisSection(
                    title: "✅ DOĞRU YAPILANLAR",
                    items: analysisResult.correctPoints,
                    color: .success
                )
                
                // Errors
                AnalysisSection(
                    title: "❌ DÜZELTİLMESİ GEREKENLER",
                    items: analysisResult.errors,
                    color: .error
                )
                
                // Suggestions
                AnalysisSection(
                    title: "💡 ÖNERİLER",
                    items: analysisResult.suggestions,
                    color: .info
                )
                
                // Chat Button
                Button {
                    showChat = true
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Soru Sor")
                            .font(.titleMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.primaryBlack)
                    .foregroundColor(.primaryWhite)
                    .cornerRadius(CornerRadius.md)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView(analysisResult: analysisResult)
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView(url: analysisResult.videoURL)
        }
    }
}

struct ScoreCard: View {
    let score: Int
    
    var scoreColor: Color {
        switch score {
        case 0..<50: return .error
        case 50..<75: return .warning
        default: return .success
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("\(score)/100")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(scoreColor)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 8)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 8)
                }
            }
            .frame(height: 8)
            .cornerRadius(CornerRadius.full)
        }
        .padding(Spacing.lg)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

struct AnalysisSection: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.labelLarge)
                .foregroundColor(.textSecondary)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Text("•")
                        .foregroundColor(color)
                    Text(item)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}
```

### 4. Analysis Loading View

**Wireframe:**
```
┌────────────────────────────────┐
│                                │
│                                │
│      [Loading Animation]       │
│                                │
│   ✓ Video işleniyor...        │ ← Completed step (green)
│   ✓ AI'ya gönderiliyor...     │ ← Completed step
│   ⏳ Form analiz ediliyor...   │ ← Current step (animated)
│                                │
│   ━━━━━━━━━━━━━━━━━━━━━       │ ← Progress bar (66%)
│                                │
└────────────────────────────────┘
```

**Kod Snippet:**
```swift
struct AnalysisLoadingView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Loading animation
            ProgressView()
                .scaleEffect(2)
                .padding(.bottom, Spacing.xl)
            
            // Steps
            VStack(alignment: .leading, spacing: Spacing.md) {
                LoadingStep(
                    title: "Video işleniyor...",
                    isCompleted: viewModel.state.rawValue > AnalysisState.processingVideo.rawValue,
                    isCurrent: viewModel.state == .processingVideo
                )
                
                LoadingStep(
                    title: "AI'ya gönderiliyor...",
                    isCompleted: viewModel.state.rawValue > AnalysisState.uploadingToAI.rawValue,
                    isCurrent: viewModel.state == .uploadingToAI
                )
                
                LoadingStep(
                    title: "Form analiz ediliyor...",
                    isCompleted: viewModel.state == .completed,
                    isCurrent: viewModel.state == .analyzingForm
                )
            }
            .padding(.horizontal, Spacing.xl)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.primaryBlack)
                        .frame(width: geometry.size.width * progressPercentage, height: 4)
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, Spacing.lg)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    var progressPercentage: CGFloat {
        switch viewModel.state {
        case .processingVideo: return 0.33
        case .uploadingToAI: return 0.66
        case .analyzingForm: return 0.90
        case .completed: return 1.0
        default: return 0
        }
    }
}

struct LoadingStep: View {
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
            } else if isCurrent {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray300)
            }
            
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(isCompleted || isCurrent ? .textPrimary : .textTertiary)
        }
    }
}
```

### 5. Paywall View (Premium)

**Wireframe:**
```
┌────────────────────────────────┐
│   ✕                            │
├────────────────────────────────┤
│                                │
│   🎉 Ücretsiz Denemeni         │
│      Tamamladın!               │
│                                │
│   3 analiz yaptın, uygulama    │
│   nasıldı?                     │
│                                │
│   💎 Premium ile devam et:     │
│                                │
│   ┌────────────────────────┐   │
│   │ ✓ Sınırsız analiz      │   │
│   │ ✓ İlk 7 gün ücretsiz   │   │
│   │ ✓ İstediğin zaman iptal│   │
│   └────────────────────────┘   │
│                                │
│   ┌────────────────────────┐   │
│   │ 📅 Aylık - 2 USD/ay   │   │ ← Selected plan
│   └────────────────────────┘   │
│   ┌────────────────────────┐   │
│   │ 📅 Yıllık - 20 USD/yıl │   │
│   │    %17 indirim         │   │
│   └────────────────────────┘   │
│                                │
│   ┌────────────────────────┐   │
│   │ 7 Gün Ücretsiz Başla  │   │ ← Primary CTA
│   └────────────────────────┘   │
│                                │
│   Yarın Tekrar Dene            │ ← Secondary action
│                                │
│   Restore Purchases            │ ← Tertiary link
│                                │
└────────────────────────────────┘
```

## 🎭 Components Library

### Custom Button Styles

```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(Color.primaryBlack)
            .foregroundColor(.primaryWhite)
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(Color.primaryWhite)
            .foregroundColor(.primaryBlack)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.gray300, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
```

## 📐 Layout Guidelines

- **Safe Area**: Tüm content safe area içinde
- **Padding**: Minimum 16pt yan padding
- **Touch Targets**: Minimum 44x44pt
- **Spacing**: Consistent spacing sistemi kullan
- **Readability**: Max line width ~65 karakter

## 🌙 Dark Mode (Opsiyonel - Gelecek Versiyon)

İlk versiyonda sadece light mode. Dark mode için:
- Background siyah olur
- Text beyaz olur
- Gray scale ters çevrilir

---

**Not**: Tüm UI elemanları Apple HIG (Human Interface Guidelines) standardlarına uygun tasarlanmıştır.
