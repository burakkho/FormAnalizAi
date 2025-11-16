//
//  AppError.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation

// MARK: - App Error Types
enum AppError: LocalizedError, Sendable {
    // Video Errors
    case videoTooShort
    case videoTooLarge
    case videoFormatNotSupported
    case videoProcessingFailed
    case thumbnailGenerationFailed
    case cameraPermissionDenied
    case photoLibraryPermissionDenied

    // Network Errors
    case networkError(String)
    case apiError(String)
    case analysisAPIFailed
    case invalidAPIResponse
    case noInternetConnection
    case rateLimitExceeded

    // Subscription Errors
    case dailyLimitReached
    case subscriptionRequired
    case purchaseFailed(String)
    case restoreFailed
    case productNotFound

    // Storage Errors
    case saveFailed
    case loadFailed
    case deleteFailed
    case fileNotFound
    case fileSystemUnavailable

    // Configuration Errors
    case configurationError(String)

    // General
    case unknown(String)

    var errorDescription: String? {
        switch self {
        // Video Errors
        case .videoTooShort:
            return "Video en az 5 saniye olmalıdır"
        case .videoTooLarge:
            return "Video dosyası çok büyük (Max: 500 MB)"
        case .videoFormatNotSupported:
            return "Video formatı desteklenmiyor"
        case .videoProcessingFailed:
            return "Video işlenirken hata oluştu"
        case .thumbnailGenerationFailed:
            return "Önizleme oluşturulamadı"
        case .cameraPermissionDenied:
            return "Kamera izni gerekli"
        case .photoLibraryPermissionDenied:
            return "Fotoğraf galerisi izni gerekli"

        // Network Errors
        case .networkError(let message):
            return "Ağ hatası: \(message)"
        case .apiError(let message):
            return "API hatası: \(message)"
        case .analysisAPIFailed:
            return "Analiz yapılırken hata oluştu"
        case .invalidAPIResponse:
            return "Geçersiz API yanıtı"
        case .noInternetConnection:
            return "İnternet bağlantısı yok"
        case .rateLimitExceeded:
            return "API limit aşıldı"

        // Subscription Errors
        case .dailyLimitReached:
            return "Günlük analiz limitine ulaştınız"
        case .subscriptionRequired:
            return "Bu özellik için premium üyelik gerekli"
        case .purchaseFailed(let reason):
            return "Satın alma başarısız: \(reason)"
        case .restoreFailed:
            return "Satın alma geri yüklenemedi"
        case .productNotFound:
            return "Ürün bulunamadı"

        // Storage Errors
        case .saveFailed:
            return "Kaydetme başarısız"
        case .loadFailed:
            return "Yükleme başarısız"
        case .deleteFailed:
            return "Silme başarısız"
        case .fileNotFound:
            return "Dosya bulunamadı"
        case .fileSystemUnavailable:
            return "Dosya sistemine erişilemiyor"

        // Configuration Errors
        case .configurationError(let message):
            return "Yapılandırma hatası: \(message)"

        // General
        case .unknown(let message):
            return "Bilinmeyen hata: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .videoTooShort:
            return "Lütfen en az 5 saniyelik bir video yükleyin"
        case .videoTooLarge:
            return "Daha küçük bir video seçin veya videoyu kısaltın"
        case .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return "Ayarlar > Gizlilik'ten izni etkinleştirin"
        case .dailyLimitReached:
            return "Yarın tekrar deneyin veya premium üyeliğe geçin"
        case .noInternetConnection:
            return "İnternet bağlantınızı kontrol edin"
        case .analysisAPIFailed:
            return "Lütfen tekrar deneyin"
        case .rateLimitExceeded:
            return "Çok fazla istek gönderdiniz. Lütfen 1-2 dakika bekleyin"
        case .fileSystemUnavailable:
            return "Cihaz belleğinizi kontrol edin veya uygulamayı yeniden başlatın"
        case .configurationError:
            return "Uygulamayı yeniden yükleyin. Sorun devam ederse destek ekibiyle iletişime geçin"
        default:
            return nil
        }
    }
}
