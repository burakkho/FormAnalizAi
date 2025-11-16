//
//  OnboardingView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "video.fill",
            title: "Video Kaydet",
            description: "Egzersizinizi kamera ile kaydedin veya galerinizden bir video seçin",
            color: .blue
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "AI ile Analiz",
            description: "Yapay zeka formunuzu analiz eder ve detaylı geri bildirim verir",
            color: .purple
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Gelişiminizi İzleyin",
            description: "Analizlerinizi kaydedin, geçmişinizi görüntüleyin ve AI ile sohbet edin",
            color: .green
        ),
        OnboardingPage(
            icon: "crown.fill",
            title: "Premium'a Geçin",
            description: "Günlük 3 ücretsiz analiz veya sınırsız erişim için premium üye olun",
            color: .yellow
        )
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Atla")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, Constants.UI.mediumPadding)
                            .padding(.vertical, Constants.UI.smallPadding)
                    }
                }
                .padding(.top, Constants.UI.mediumPadding)
                .padding(.horizontal, Constants.UI.mediumPadding)

                Spacer()

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                Spacer()

                // Page Indicators
                HStack(spacing: Constants.UI.smallSpacing) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, Constants.UI.largePadding)

                // Action Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "İleri" : "Başla")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.buttonHeight)
                        .background(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(Constants.UI.cornerRadius)
                        .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, Constants.UI.horizontalPadding)
                .padding(.bottom, Constants.UI.extraLargePadding)
            }
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.impact(.medium)
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Constants.UI.extraLargeSpacing) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.3), page.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.color)
            }
            .padding(.bottom, Constants.UI.mediumPadding)

            // Text Content
            VStack(spacing: Constants.UI.mediumSpacing) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Constants.UI.horizontalPadding)
            }
        }
        .padding(.horizontal, Constants.UI.largePadding)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
