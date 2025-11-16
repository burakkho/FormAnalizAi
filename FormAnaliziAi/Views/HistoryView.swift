//
//  HistoryView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
import UIKit
import ImageIO

struct HistoryView: View {
    @Binding var navigationPath: NavigationPath

    @Environment(StorageService.self) private var storageService

    @State private var viewModel: HistoryViewModel?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel = viewModel {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else if viewModel.sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.UI.smallPadding) { // ✅ Already using LazyVStack
                            ForEach(viewModel.sessions) { session in
                                SessionCard(
                                    session: session,
                                    thumbnailURL: storageService.getThumbnailURL(for: session)
                                ) {
                                    navigationPath.append(AppRoute.analysisResult(session))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteSession(session)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately) // ✅ Keyboard optimization
                }
            }
        }
        .navigationTitle("Geçmiş")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Initialize ViewModel lazily
            if viewModel == nil {
                viewModel = HistoryViewModel(storageService: storageService)
                await viewModel?.loadSessions()
            }
        }
        .refreshable {
            await viewModel?.refreshSessions()
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel?.showError ?? false },
            set: { if !$0 { viewModel?.showError = false } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            if let error = viewModel?.error {
                Text(error.errorDescription ?? "Bilinmeyen hata")
            }
        }
    }

}

// MARK: - Session Card Component
struct SessionCard: View {
    let session: AnalysisSession
    let thumbnailURL: URL?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.UI.mediumSpacing) {
                SessionThumbnailView(
                    thumbnailURL: thumbnailURL,
                    tint: session.analysisResult.scoreColor
                )

                // Info
                VStack(alignment: .leading, spacing: Constants.UI.smallSpacing) {
                    // Exercise name
                    Text(session.exerciseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    // Score & Chat
                    HStack(spacing: Constants.UI.smallBadgePaddingHorizontal) {
                        Badge(
                            icon: "star.fill",
                            text: "\(session.analysisResult.score)",
                            color: session.analysisResult.scoreColor,
                            size: .medium
                        )

                        if session.hasChatHistory {
                            Badge(
                                icon: "message.fill",
                                text: "\(session.chatHistory.count)",
                                color: AppColors.primaryBlue,
                                size: .small
                            )
                        }
                    }

                    // Date
                    Text(session.createdAt, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.glassBorder)
            }
            .glassCard(cornerRadius: Constants.UI.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thumbnail View
struct SessionThumbnailView: View {
    let thumbnailURL: URL?
    let tint: Color

    @StateObject private var loader = ThumbnailLoader()

    private let size = Constants.UI.largeButtonHeight + 15

    var body: some View {
        ZStack {
            if let image = loader.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(Constants.UI.smallCornerRadius + 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius + 2)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius + 2)
                    .fill(tint.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(tint.opacity(0.6))
                    )
                    .overlay(alignment: .center) {
                        if loader.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
        }
        .task {
            await loader.loadThumbnail(from: thumbnailURL, targetSize: thumbnailPixelSize)
        }
        .onChange(of: thumbnailURL?.path) { _, _ in
            loader.reset()
            Task { await loader.loadThumbnail(from: thumbnailURL, targetSize: thumbnailPixelSize) }
        }
    }

    private var thumbnailPixelSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: size * scale, height: size * scale)
    }
}

// MARK: - Thumbnail Loader (ViewModel)
@MainActor
final class ThumbnailLoader: ObservableObject {
    @Published var image: Image?
    @Published var isLoading = false

    private static let cache = NSCache<NSURL, UIImage>()
    private var currentURL: URL?

    func loadThumbnail(from url: URL?, targetSize: CGSize) async {
        guard !isLoading else { return }
        guard let url else { return }

        currentURL = url

        if let cached = Self.cache.object(forKey: url as NSURL) {
            image = Image(uiImage: cached)
            return
        }

        isLoading = true
        let uiImage = await Task.detached(priority: .utility) { () -> UIImage? in
            guard let cgImage = ThumbnailLoader.downsampledImage(at: url, targetSize: targetSize) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }.value

        guard currentURL == url else { return }

        if let uiImage {
            Self.cache.setObject(uiImage, forKey: url as NSURL)
            image = Image(uiImage: uiImage)
        }

        isLoading = false
    }

    func reset() {
        image = nil
        isLoading = false
        currentURL = nil
    }

    private static func downsampledImage(at url: URL, targetSize: CGSize) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return nil
        }

        let maxDimension = max(targetSize.width, targetSize.height)
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxDimension))
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary)
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: Constants.UI.largePadding) {
            Image(systemName: "clock.fill")
                .font(.iconMedium)
                .foregroundStyle(.gray)

            Text("Henüz analiz yok")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("İlk analizinizi yapmak için ana sayfadan başlayın")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.UI.extraLargePadding)
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    NavigationStack(path: $path) {
        HistoryView(navigationPath: $path)
            .environment(StorageService())
    }
}
