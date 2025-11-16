//
//  SettingsViewModel.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation
import StoreKit

@Observable
@MainActor
class SettingsViewModel {
    // Dependencies
    private let storageService: StorageService
    private let subscriptionService: SubscriptionService

    // Published State
    var cacheSize: String = "0 KB"
    var isRestoring: Bool = false
    var error: AppError?

    init(storageService: StorageService, subscriptionService: SubscriptionService) {
        self.storageService = storageService
        self.subscriptionService = subscriptionService
        updateCacheSize()
    }

    // MARK: - Cache Management
    func updateCacheSize() {
        cacheSize = storageService.getCacheSize()
    }

    func clearCache() {
        do {
            try storageService.clearVideoCache()
            updateCacheSize()
            HapticManager.shared.notification(.success)
            Configuration.log("Cache cleared successfully", category: .storage, level: .info)
        } catch {
            Configuration.log("Failed to clear cache: \(error)", category: .storage, level: .error)
            self.error = .saveFailed
            HapticManager.shared.notification(.error)
        }
    }

    func deleteAllData() {
        do {
            try storageService.deleteAllData()
            updateCacheSize()
            HapticManager.shared.notification(.success)
            Configuration.log("All data deleted successfully", category: .storage, level: .info)
        } catch {
            Configuration.log("Failed to delete all data: \(error)", category: .storage, level: .error)
            self.error = .saveFailed
            HapticManager.shared.notification(.error)
        }
    }

    // MARK: - Subscription Management
    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await subscriptionService.updateSubscriptionStatus()
            HapticManager.shared.notification(.success)
            Configuration.log("Purchases restored successfully", category: .subscription, level: .info)
        } catch {
            Configuration.log("Failed to restore purchases: \(error)", category: .subscription, level: .error)
            self.error = .purchaseFailed(error.localizedDescription)
            HapticManager.shared.notification(.error)
        }
    }

    // MARK: - Language Management
    func changeLanguage(to languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Configuration.log("Language changed to: \(languageCode)", category: .general, level: .info)
    }

    func getCurrentLanguage() -> String {
        return Locale.current.language.languageCode?.identifier ?? "tr"
    }
}
