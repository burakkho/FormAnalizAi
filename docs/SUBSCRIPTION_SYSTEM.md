# Form Analizi AI - Subscription System (StoreKit 2)

## 💎 Abonelik Modeli

### Freemium Yapısı

**Ücretsiz Kullanıcı:**
- Günde 3 analiz
- Tüm egzersizler
- Chat özelliği
- Geçmiş görüntüleme

**Premium Kullanıcı:**
- Sınırsız analiz
- Tüm özellikler

### Fiyatlandırma

**Aylık:**
- Fiyat: 2 USD/ay
- Product ID: `com.formanalizi.premium.monthly`
- 7 gün ücretsiz deneme

**Yıllık:**
- Fiyat: 20 USD/yıl
- Product ID: `com.formanalizi.premium.yearly`
- %17 indirim (24 USD → 20 USD)
- 7 gün ücretsiz deneme

## 🏗️ StoreKit 2 Implementation

### Configuration

#### 1. App Store Connect Setup

1. **App Store Connect** → **My Apps** → **Form Analizi AI**
2. **Subscriptions** → **Create Subscription Group**
   - Group Name: "Premium Membership"
3. **Add Subscription**:
   - Monthly:
     - Reference Name: "Premium Monthly"
     - Product ID: `com.formanalizi.premium.monthly`
     - Duration: 1 month
     - Price: $1.99 (App Store Connect tier)
     - Free Trial: 7 days
   - Yearly:
     - Reference Name: "Premium Yearly"
     - Product ID: `com.formanalizi.premium.yearly`
     - Duration: 1 year
     - Price: $19.99
     - Free Trial: 7 days

4. **Subscription Localization**:
   - Türkçe: "Premium Üyelik - Aylık" / "Premium Üyelik - Yıllık"
   - English: "Premium Membership - Monthly" / "Premium Membership - Yearly"

#### 2. Xcode Configuration

**Capabilities:**
```
Target → Signing & Capabilities → + Capability → In-App Purchase
```

**StoreKit Configuration File (Testing):**
```
File → New → File → StoreKit Configuration File
```

### Models

```swift
// SubscriptionProduct.swift
import StoreKit

enum SubscriptionTier: String, Codable {
    case monthly = "com.formanalizi.premium.monthly"
    case yearly = "com.formanalizi.premium.yearly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return String(localized: "Aylık")
        case .yearly:
            return String(localized: "Yıllık")
        }
    }
    
    var description: String {
        switch self {
        case .monthly:
            return String(localized: "2 USD/ay")
        case .yearly:
            return String(localized: "20 USD/yıl - %17 indirim")
        }
    }
}

struct SubscriptionStatus: Codable {
    var isPremium: Bool
    var currentTier: SubscriptionTier?
    var expirationDate: Date?
    var isInTrialPeriod: Bool
    var originalPurchaseDate: Date?
    
    var isActive: Bool {
        guard let expirationDate = expirationDate else {
            return false
        }
        return isPremium && expirationDate > Date()
    }
}

struct DailyUsage: Codable {
    var count: Int
    var date: Date
    
    var isExpired: Bool {
        !Calendar.current.isDateInToday(date)
    }
}
```

### SubscriptionService

```swift
// SubscriptionService.swift
import StoreKit
import Foundation

@MainActor
class SubscriptionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var subscriptionStatus: SubscriptionStatus = SubscriptionStatus(
        isPremium: false,
        isInTrialPeriod: false
    )
    
    @Published var availableProducts: [Product] = []
    @Published var purchaseInProgress = false
    @Published var dailyUsage: DailyUsage = DailyUsage(count: 0, date: Date())
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    
    private let productIDs: [String] = [
        SubscriptionTier.monthly.rawValue,
        SubscriptionTier.yearly.rawValue
    ]
    
    // MARK: - Init
    
    init() {
        // Load saved status
        loadSubscriptionStatus()
        loadDailyUsage()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            
            // Sort: monthly first, then yearly
            self.availableProducts = products.sorted { product1, product2 in
                if product1.id == SubscriptionTier.monthly.rawValue {
                    return true
                }
                return false
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Finish the transaction
            await transaction.finish()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Check Subscription Status
    
    func updateSubscriptionStatus() async {
        var status = SubscriptionStatus(isPremium: false, isInTrialPeriod: false)
        
        // Check all subscription transactions
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            // Check if it's one of our subscription products
            guard let tier = SubscriptionTier(rawValue: transaction.productID) else {
                continue
            }
            
            // Active subscription found
            if transaction.revocationDate == nil {
                status.isPremium = true
                status.currentTier = tier
                status.expirationDate = transaction.expirationDate
                status.originalPurchaseDate = transaction.originalPurchaseDate
                
                // Check if in trial period
                if let subscriptionInfo = transaction.subscriptionStatus {
                    status.isInTrialPeriod = subscriptionInfo.state == .subscribed && 
                                             subscriptionInfo.renewalInfo.isInBillingRetryPeriod == false &&
                                             transaction.isInIntroOfferPeriod
                }
                
                break
            }
        }
        
        self.subscriptionStatus = status
        saveSubscriptionStatus()
    }
    
    // MARK: - Listen for Transactions
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                // Update subscription status
                await self.updateSubscriptionStatus()
                
                // Finish transaction
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Verify Transaction
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Daily Usage Tracking
    
    func incrementDailyUsage() {
        // Reset if date changed
        if dailyUsage.isExpired {
            dailyUsage = DailyUsage(count: 0, date: Date())
        }
        
        dailyUsage.count += 1
        saveDailyUsage()
    }
    
    func canAnalyze() -> Bool {
        // Premium users: unlimited
        if subscriptionStatus.isPremium {
            return true
        }
        
        // Free users: check daily limit
        if dailyUsage.isExpired {
            // New day, reset count
            dailyUsage = DailyUsage(count: 0, date: Date())
            saveDailyUsage()
            return true
        }
        
        return dailyUsage.count < 3
    }
    
    func remainingAnalyses() -> Int {
        if subscriptionStatus.isPremium {
            return .max // Unlimited
        }
        
        if dailyUsage.isExpired {
            return 3
        }
        
        return max(0, 3 - dailyUsage.count)
    }
    
    // MARK: - Persistence
    
    private func saveSubscriptionStatus() {
        if let encoded = try? JSONEncoder().encode(subscriptionStatus) {
            UserDefaults.standard.set(encoded, forKey: "subscription_status")
        }
    }
    
    private func loadSubscriptionStatus() {
        if let data = UserDefaults.standard.data(forKey: "subscription_status"),
           let decoded = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) {
            subscriptionStatus = decoded
        }
    }
    
    private func saveDailyUsage() {
        if let encoded = try? JSONEncoder().encode(dailyUsage) {
            UserDefaults.standard.set(encoded, forKey: "daily_usage")
        }
    }
    
    private func loadDailyUsage() {
        if let data = UserDefaults.standard.data(forKey: "daily_usage"),
           let decoded = try? JSONDecoder().decode(DailyUsage.self, from: data) {
            dailyUsage = decoded
        } else {
            dailyUsage = DailyUsage(count: 0, date: Date())
        }
    }
}

// MARK: - Errors

enum StoreError: Error {
    case failedVerification
}
```

### Paywall View

```swift
// PaywallView.swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        Text("🎉")
                            .font(.system(size: 60))
                        
                        Text("Ücretsiz Denemeni Tamamladın!")
                            .font(.displayMedium)
                            .multilineTextAlignment(.center)
                        
                        Text("3 analiz yaptın, uygulama nasıldı?")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Features
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("💎 Premium ile devam et:")
                            .font(.titleLarge)
                        
                        FeatureRow(icon: "checkmark.circle.fill", text: "Sınırsız analiz")
                        FeatureRow(icon: "checkmark.circle.fill", text: "İlk 7 gün ücretsiz")
                        FeatureRow(icon: "checkmark.circle.fill", text: "İstediğin zaman iptal")
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    // Product Selection
                    VStack(spacing: Spacing.md) {
                        ForEach(subscriptionService.availableProducts, id: \.id) { product in
                            ProductCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id
                            )
                            .onTapGesture {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    // Purchase Button
                    Button {
                        Task {
                            if let product = selectedProduct {
                                try await subscriptionService.purchase(product)
                                dismiss()
                            }
                        }
                    } label: {
                        if subscriptionService.purchaseInProgress {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("7 Gün Ücretsiz Başla")
                                .font(.titleMedium)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedProduct == nil || subscriptionService.purchaseInProgress)
                    .padding(.horizontal, Spacing.lg)
                    
                    // Secondary Actions
                    VStack(spacing: Spacing.sm) {
                        Button("Yarın Tekrar Dene") {
                            dismiss()
                        }
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        
                        Button("Restore Purchases") {
                            Task {
                                await subscriptionService.restorePurchases()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    }
                    
                    // Legal
                    HStack(spacing: Spacing.xs) {
                        Link("Terms", destination: URL(string: "https://formanalizi.com/terms")!)
                        Text("•")
                        Link("Privacy", destination: URL(string: "https://formanalizi.com/privacy")!)
                    }
                    .font(.caption)
                    .foregroundColor(.textTertiary)
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
        }
        .onAppear {
            // Select monthly by default
            selectedProduct = subscriptionService.availableProducts.first
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.success)
            Text(text)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(tierName)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(product.displayPrice)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                
                if product.id == SubscriptionTier.yearly.rawValue {
                    Text("%17 indirim")
                        .font(.caption)
                        .foregroundColor(.success)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.success.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primaryBlack)
                    .font(.title2)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray300)
                    .font(.title2)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isSelected ? Color.primaryBlack : Color.clear, lineWidth: 2)
        )
        .cornerRadius(CornerRadius.md)
    }
    
    var tierName: String {
        if product.id == SubscriptionTier.monthly.rawValue {
            return "Aylık"
        } else {
            return "Yıllık"
        }
    }
}
```

### Integration with Analysis Flow

```swift
// AnalysisViewModel.swift - Modified
@MainActor
class AnalysisViewModel: ObservableObject {
    // ... existing code ...
    
    @Published var showPaywall = false
    private let subscriptionService: SubscriptionService
    
    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }
    
    func analyzeVideo(url: URL, exercise: Exercise) async {
        // Check if user can analyze
        guard subscriptionService.canAnalyze() else {
            showPaywall = true
            return
        }
        
        // ... existing analysis code ...
        
        // Increment usage after successful analysis
        subscriptionService.incrementDailyUsage()
    }
}
```

## 🧪 Testing

### Local Testing (StoreKit Configuration File)

1. **Create StoreKit Configuration File**
2. **Add Products**:
   - Monthly: $1.99
   - Yearly: $19.99
3. **Run app** with StoreKit testing enabled
4. **Test scenarios**:
   - Purchase monthly
   - Purchase yearly
   - Cancel subscription
   - Restore purchases
   - Trial period

### Sandbox Testing

1. **Create Sandbox Tester** in App Store Connect
2. **Test on device** (not simulator)
3. **Verify**:
   - Purchase flow
   - Trial period
   - Renewal
   - Cancellation

## 📊 Analytics & Metrics

### Track Important Events

```swift
// Analytics events to track
enum SubscriptionEvent {
    case paywallShown
    case productViewed(SubscriptionTier)
    case purchaseStarted(SubscriptionTier)
    case purchaseCompleted(SubscriptionTier)
    case purchaseFailed(Error)
    case trialStarted(SubscriptionTier)
    case subscriptionCancelled
    case subscriptionRenewed(SubscriptionTier)
}

// Example with Firebase Analytics (opsiyonel)
func trackSubscriptionEvent(_ event: SubscriptionEvent) {
    switch event {
    case .paywallShown:
        Analytics.logEvent("paywall_shown", parameters: nil)
    case .purchaseCompleted(let tier):
        Analytics.logEvent("purchase_completed", parameters: [
            "tier": tier.rawValue
        ])
    // ... other events
    default:
        break
    }
}
```

### Key Metrics to Monitor

- **Paywall Impression Rate**: Kaç kullanıcı paywall gördü
- **Trial Start Rate**: Kaç kullanıcı trial başlattı
- **Trial to Paid Conversion**: Trial'dan paid'e dönüşüm
- **Monthly vs Yearly**: Hangi plan daha popüler
- **Churn Rate**: Abonelik iptal oranı
- **LTV (Lifetime Value)**: Kullanıcı başına gelir

## 🔒 Best Practices

1. **Transaction Verification**: Her zaman verify et
2. **Finish Transactions**: Transaction'ları finish et
3. **Handle Errors**: Tüm edge case'leri handle et
4. **Restore Purchases**: Restore butonu ekle
5. **Privacy**: Kullanıcı purchase bilgisi saklanmamalı
6. **Testing**: Hem sandbox hem production test et
7. **Localization**: Fiyatları yerel para biriminde göster

## 📝 Legal Requirements

### Privacy Policy
- Abonelik bilgilerinin nasıl kullanıldığı
- Apple'ın subscription management'ı
- İptal prosedürü

### Terms of Service
- Abonelik koşulları
- Fiyatlandırma
- Ödeme ve yenileme
- İptal politikası
- Para iade politikası

---

**Not**: StoreKit 2 iOS 15+ gerektirir. iOS 14 support gerekirse StoreKit 1 kullan.
