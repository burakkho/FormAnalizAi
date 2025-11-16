//
//  SubscriptionService.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import StoreKit
import Observation

// MARK: - Subscription Service
@Observable
@MainActor
class SubscriptionService {
    // Subscription State (UI state on main thread)
    var isPremium: Bool = false
    var dailyAnalysisCount: Int = 0
    var lastResetDate: Date = Date()

    // Purchase State (UI state on main thread)
    var availableProducts: [Product] = []
    var isPurchasing: Bool = false
    var error: AppError?

    // User Defaults
    private let defaults = UserDefaults.standard

    // Transaction listener task (managed on MainActor)
    private var transactionListener: Task<Void, Never>?

    // MARK: - Initialization
    init() {
        loadSubscriptionState()

        // Load products and check subscription in background to avoid blocking UI
        Task(priority: .userInitiated) { @MainActor [weak self] in
            guard let self = self else { return }
            await self.loadProducts()
            await self.updateSubscriptionStatus()
        }

        startTransactionListener()
    }

    deinit {
        // Access MainActor-isolated property safely
        Task { @MainActor [weak self] in
            self?.transactionListener?.cancel()
        }
    }

    // MARK: - Load Subscription State from UserDefaults
    private func loadSubscriptionState() {
        isPremium = defaults.bool(forKey: Constants.UserDefaultsKeys.isPremium)
        dailyAnalysisCount = defaults.integer(forKey: Constants.UserDefaultsKeys.dailyAnalysisCount)

        if let lastReset = defaults.object(forKey: Constants.UserDefaultsKeys.lastResetDate) as? Date {
            lastResetDate = lastReset
        }

        resetDailyCountIfNeeded()

        Configuration.log("Loaded subscription state: isPremium=\(isPremium), dailyCount=\(dailyAnalysisCount)", category: .subscription, level: .info)
    }

    private func saveSubscriptionState() {
        defaults.set(isPremium, forKey: Constants.UserDefaultsKeys.isPremium)
        defaults.set(dailyAnalysisCount, forKey: Constants.UserDefaultsKeys.dailyAnalysisCount)
        defaults.set(lastResetDate, forKey: Constants.UserDefaultsKeys.lastResetDate)
    }

    // MARK: - Daily Limit Management
    func canAnalyze() -> Bool {
        resetDailyCountIfNeeded()

        if isPremium {
            return true
        }

        return dailyAnalysisCount < Constants.Subscription.freeDailyLimit
    }

    func incrementDailyCount() {
        resetDailyCountIfNeeded()

        dailyAnalysisCount += 1
        saveSubscriptionState()

        Configuration.log("Daily analysis count incremented: \(dailyAnalysisCount)/\(Constants.Subscription.freeDailyLimit)", category: .subscription, level: .debug)
    }

    func getRemainingAnalyses() -> Int {
        resetDailyCountIfNeeded()

        if isPremium {
            return Int.max // Unlimited
        }

        return max(0, Constants.Subscription.freeDailyLimit - dailyAnalysisCount)
    }

    private func resetDailyCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            Configuration.log("Resetting daily count (new day)", category: .subscription, level: .info)
            dailyAnalysisCount = 0
            lastResetDate = Date()
            saveSubscriptionState()
        }
    }

    // MARK: - Load Products from App Store
    func loadProducts() async {
        Configuration.log("Loading products from App Store", category: .subscription, level: .info)

        do {
            let productIds = [
                Constants.Subscription.monthlyProductId,
                Constants.Subscription.yearlyProductId
            ]

            let products = try await Product.products(for: productIds)
            self.availableProducts = products.sorted { $0.price < $1.price }

            Configuration.log("Loaded \(products.count) products", category: .subscription, level: .info)
        } catch {
            Configuration.log("Failed to load products: \(error)", category: .subscription, level: .error)
            self.error = .productNotFound
        }
    }

    // MARK: - Purchase Subscription
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }

        Configuration.log("Initiating purchase for: \(product.id)", category: .subscription, level: .info)

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await updateSubscriptionStatus()

                // Finish transaction
                await transaction.finish()

                Configuration.log("Purchase successful: \(product.id)", category: .subscription, level: .info)

            case .userCancelled:
                Configuration.log("User cancelled purchase", category: .subscription, level: .info)
                throw AppError.purchaseFailed("Kullanıcı iptal etti")

            case .pending:
                Configuration.log("Purchase pending", category: .subscription, level: .info)
                throw AppError.purchaseFailed("Onay bekleniyor")

            @unknown default:
                throw AppError.purchaseFailed("Bilinmeyen durum")
            }
        } catch {
            Configuration.log("Purchase failed: \(error)", category: .subscription, level: .error)
            if let appError = error as? AppError {
                self.error = appError
                throw appError
            } else {
                let purchaseError = AppError.purchaseFailed(error.localizedDescription)
                self.error = purchaseError
                throw purchaseError
            }
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        isPurchasing = true
        error = nil
        defer { isPurchasing = false }

        Configuration.log("Restoring purchases", category: .subscription, level: .info)

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()

            if !isPremium {
                throw AppError.restoreFailed
            }

            Configuration.log("Purchases restored successfully", category: .subscription, level: .info)
        } catch {
            Configuration.log("Restore failed: \(error)", category: .subscription, level: .error)
            self.error = .restoreFailed
            throw AppError.restoreFailed
        }
    }

    // MARK: - Update Subscription Status
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is active
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                    break
                }
            } catch {
                Configuration.log("Transaction verification failed: \(error)", category: .subscription, level: .error)
            }
        }

        // Update state
        isPremium = hasActiveSubscription || Configuration.FeatureFlags.skipSubscriptionChecks
        saveSubscriptionState()

        Configuration.log("Subscription status updated: isPremium=\(isPremium)", category: .subscription, level: .info)
    }

    // MARK: - Verify Transaction
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw AppError.purchaseFailed("Doğrulanamadı")
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Get Product Price String
    func priceString(for product: Product) -> String {
        return product.displayPrice
    }

    func subscriptionPeriod(for product: Product) -> String? {
        guard let subscription = product.subscription else { return nil }

        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .month:
            return period.value == 1 ? "Aylık" : "\(period.value) Ay"
        case .year:
            return period.value == 1 ? "Yıllık" : "\(period.value) Yıl"
        default:
            return nil
        }
    }

    // MARK: - Transaction Listener
    /// Listens for transaction updates (renewals, cancellations, purchases from other devices)
    private func startTransactionListener() {
        transactionListener = Task.detached(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                guard let self = self else { break }

                do {
                    let transaction = try self.checkVerified(verificationResult)

                    // Update subscription status on transaction changes
                    await self.updateSubscriptionStatus()

                    // Finish the transaction
                    await transaction.finish()

                    Configuration.log(
                        "Transaction update processed: \(transaction.productID)",
                        category: .subscription,
                        level: .info
                    )
                } catch {
                    Configuration.log(
                        "Failed to process transaction update: \(error)",
                        category: .subscription,
                        level: .error
                    )
                }
            }
        }

        Configuration.log("Transaction listener started", category: .subscription, level: .info)
    }
}
