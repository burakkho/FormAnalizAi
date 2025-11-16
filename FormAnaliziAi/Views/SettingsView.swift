//
//  SettingsView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(StorageService.self) private var storageService
    @Environment(\.requestReview) private var requestReview

    @State private var viewModel: SettingsViewModel?
    @State private var showPaywall = false
    @State private var showClearCacheAlert = false
    @State private var showDeleteAllDataAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                // Subscription Section
                Section {
                    if subscriptionService.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Üye")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text("Sınırsız analiz")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            Text("Aktif")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown")
                                    .foregroundStyle(.yellow)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Premium'a Geç")
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text("\(subscriptionService.getRemainingAnalyses())/\(Constants.Subscription.freeDailyLimit) analiz kaldı")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                } header: {
                    Text("Abonelik")
                        .foregroundStyle(.gray)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // General Section
                Section {
                    // Language Selection
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)

                        Text("Dil")
                            .foregroundStyle(.white)

                        Spacer()

                        Menu {
                            Button {
                                viewModel?.changeLanguage(to: "tr")
                            } label: {
                                Label("Türkçe", systemImage: viewModel?.getCurrentLanguage() == "tr" ? "checkmark" : "")
                            }

                            Button {
                                viewModel?.changeLanguage(to: "en")
                            } label: {
                                Label("English", systemImage: viewModel?.getCurrentLanguage() == "en" ? "checkmark" : "")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel?.getCurrentLanguage() == "tr" ? "Türkçe" : "English")
                                    .foregroundStyle(.gray)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                } header: {
                    Text("Genel")
                        .foregroundStyle(.gray)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // Data Management Section
                Section {
                    // Cache Size
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundStyle(.blue)

                        Text("Önbellek Boyutu")
                            .foregroundStyle(.white)

                        Spacer()

                        Text(viewModel?.cacheSize ?? "0 KB")
                            .foregroundStyle(.gray)
                    }

                    // Clear Cache
                    Button {
                        showClearCacheAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.orange)

                            Text("Önbelleği Temizle")
                                .foregroundStyle(.white)

                            Spacer()
                        }
                    }

                    // Delete All Data
                    Button {
                        showDeleteAllDataAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)

                            Text("Tüm Verileri Sil")
                                .foregroundStyle(.white)

                            Spacer()
                        }
                    }
                } header: {
                    Text("Veri Yönetimi")
                        .foregroundStyle(.gray)
                } footer: {
                    Text("Önbelleği temizlemek videoları siler. Tüm verileri silmek analiz geçmişinizi de siler.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // Additional Section
                Section {
                    // Restore Purchases
                    if !subscriptionService.isPremium {
                        Button {
                            Task {
                                await viewModel?.restorePurchases()
                            }
                        } label: {
                            HStack {
                                if viewModel?.isRestoring == true {
                                    ProgressView()
                                        .tint(.blue)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.blue)
                                }

                                Text("Satın Alımları Geri Yükle")
                                    .foregroundStyle(.white)

                                Spacer()
                            }
                        }
                        .disabled(viewModel?.isRestoring == true)
                    }

                    // Rate App
                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)

                            Text("Uygulamayı Değerlendir")
                                .foregroundStyle(.white)

                            Spacer()
                        }
                    }

                    // Share App
                    if let appURL = URL(string: "https://apps.apple.com/app/id\(Constants.App.appStoreId)") {
                        ShareLink(item: appURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.green)

                                Text("Uygulamayı Paylaş")
                                    .foregroundStyle(.white)

                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Diğer")
                        .foregroundStyle(.gray)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // App Info Section
                Section {
                    HStack {
                        Text("Versiyon")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundStyle(.gray)
                    }
                } header: {
                    Text("Uygulama")
                        .foregroundStyle(.gray)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // Support Section
                Section {
                    if let supportURL = URL(string: Constants.Links.support) {
                        Link(destination: supportURL) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.blue)

                                Text("Destek")
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    if let privacyURL = URL(string: Constants.Links.privacyPolicy) {
                        Link(destination: privacyURL) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundStyle(.blue)

                                Text("Gizlilik Politikası")
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    if let termsURL = URL(string: Constants.Links.termsOfService) {
                        Link(destination: termsURL) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)

                                Text("Kullanım Şartları")
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                } header: {
                    Text("Destek")
                        .foregroundStyle(.gray)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Önbelleği Temizle", isPresented: $showClearCacheAlert) {
            Button("İptal", role: .cancel) { }
            Button("Temizle", role: .destructive) {
                viewModel?.clearCache()
            }
        } message: {
            Text("Kaydedilen tüm videolar ve küçük resimler silinecek. Analiz geçmişiniz korunacak.")
        }
        .alert("Tüm Verileri Sil", isPresented: $showDeleteAllDataAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel?.deleteAllData()
            }
        } message: {
            Text("Tüm videolar, küçük resimler ve analiz geçmişiniz kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
        .task {
            // Initialize ViewModel lazily (only once)
            if viewModel == nil {
                viewModel = SettingsViewModel(
                    storageService: storageService,
                    subscriptionService: subscriptionService
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(SubscriptionService())
            .environment(StorageService())
    }
}
