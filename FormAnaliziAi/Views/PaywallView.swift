//
//  PaywallView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, AppColors.primaryBlue.opacity(Constants.UI.glassOverlay30), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.UI.largeSpacing) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)

                    // Header
                    VStack(spacing: Constants.UI.mediumSpacing) {
                        Image(systemName: "crown.fill")
                            .font(.iconMedium)
                            .foregroundStyle(.yellow)

                        Text("Premium Üyelik")
                            .font(.appTitle)
                            .foregroundStyle(.white)

                        Text("Formunuzu mükemmelleştirin")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }

                    // Features
                    VStack(spacing: Constants.UI.mediumSpacing) {
                        FeatureRow(icon: "infinity", title: "Sınırsız Analiz", description: "Günlük limit yok")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Gelişim Takibi", description: "Detaylı istatistikler")
                        FeatureRow(icon: "message.fill", title: "Öncelikli Destek", description: "AI koçluk")
                        FeatureRow(icon: "sparkles", title: "Erken Erişim", description: "Yeni özelliklere ilk siz ulaşın")
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(Constants.UI.largeCornerRadius)
                    .padding(.horizontal)

                    // Products
                    if subscriptionService.availableProducts.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        VStack(spacing: Constants.UI.smallPadding) {
                            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                                ProductCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    subscriptionService: subscriptionService
                                ) {
                                    selectedProduct = product
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Purchase Button
                    Button {
                        purchase()
                    } label: {
                        HStack(spacing: Constants.UI.smallPadding) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Başlat")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.buttonHeight)
                        .background(selectedProduct != nil ? .white : .gray)
                        .foregroundStyle(.black)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal)

                    // Restore
                    Button {
                        restore()
                    } label: {
                        Text("Satın Alımları Geri Yükle")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .disabled(isPurchasing)

                    // Fine print
                    Text("7 gün ücretsiz deneme. İstediğiniz zaman iptal edebilirsiniz.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            // Pre-select yearly if available
            if let yearlyProduct = subscriptionService.availableProducts.first(where: { $0.id == Constants.Subscription.yearlyProductId }) {
                selectedProduct = yearlyProduct
            } else {
                selectedProduct = subscriptionService.availableProducts.first
            }
        }
    }

    // MARK: - Actions
    private func purchase() {
        guard let product = selectedProduct else { return }

        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await subscriptionService.purchase(product)
                dismiss()
            } catch {
                // Error handled in SubscriptionService
            }
        }
    }

    private func restore() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await subscriptionService.restorePurchases()
                dismiss()
            } catch {
                // Error handled in SubscriptionService
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
    }
}

// MARK: - Product Card Component
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let subscriptionService: SubscriptionService
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(subscriptionService.subscriptionPeriod(for: product) ?? "")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if isYearly {
                            Text("17% İndirim")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.yellow.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }

                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    if isYearly {
                        Text("Aylık sadece ₺17")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? .white : .gray, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding()
            .background(isSelected ? .white.opacity(0.1) : .white.opacity(0.05))
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(isSelected ? .white : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var isYearly: Bool {
        product.id == Constants.Subscription.yearlyProductId
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionService())
}
