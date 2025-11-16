//
//  AnalysisResultView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
import UIKit

struct AnalysisResultView: View {
    let session: AnalysisSession
    @Binding var navigationPath: NavigationPath

    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.UI.sectionSpacing) {
                    // Score Card
                    ScoreCard(result: session.analysisResult)
                        .padding(.top, Constants.UI.largePadding)

                    // Feedback Sections
                    VStack(spacing: Constants.UI.mediumSpacing) {
                        // General Feedback
                        FeedbackSection(
                            title: "Genel Değerlendirme",
                            icon: "doc.text.fill",
                            color: AppColors.primaryBlue,
                            content: session.analysisResult.feedback
                        )

                        // Correct Points
                        if !session.analysisResult.correctPoints.isEmpty {
                            BulletListSection(
                                title: "Doğru Yapılan",
                                icon: "checkmark.circle.fill",
                                color: AppColors.successGreen,
                                items: session.analysisResult.correctPoints
                            )
                        }

                        // Errors
                        if !session.analysisResult.errors.isEmpty {
                            BulletListSection(
                                title: "Hatalar",
                                icon: "xmark.circle.fill",
                                color: AppColors.errorRed,
                                items: session.analysisResult.errors
                            )
                        }

                        // Suggestions
                        if !session.analysisResult.suggestions.isEmpty {
                            BulletListSection(
                                title: "Öneriler",
                                icon: "lightbulb.fill",
                                color: AppColors.warningOrange,
                                items: session.analysisResult.suggestions
                            )
                        }
                    }

                    // Action Buttons
                    VStack(spacing: Constants.UI.smallPadding) {
                        // Chat Button
                        Button {
                            navigationPath.append(AppRoute.chat(session))
                        } label: {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "message.fill")
                                    .font(.title3)
                                Text("Soru Sor")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.primary)

                        // Share Button
                        Button {
                            showShareSheet = true
                        } label: {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                Text("Paylaş")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.secondary)

                        // Complete Button
                        Button {
                            // Clear navigation path to return to home
                            navigationPath.removeLast(navigationPath.count)
                        } label: {
                            HStack(spacing: Constants.UI.smallPadding) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Analizi Tamamla")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.UI.buttonHeight)
                            .background(AppColors.glassOverlay20)
                            .cornerRadius(Constants.UI.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.bottom, Constants.UI.largePadding)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(session.exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems())
        }
    }

    private var shareSummary: String {
        let result = session.analysisResult
        var sections: [String] = []
        sections.append("\(result.exerciseName) analizi - Skor: \(result.score)/100")
        sections.append("Genel: \(result.feedback)")

        if !result.correctPoints.isEmpty {
            sections.append("Doğru Yapılanlar:\n- " + result.correctPoints.joined(separator: "\n- "))
        }

        if !result.errors.isEmpty {
            sections.append("Düzeltilmesi Gerekenler:\n- " + result.errors.joined(separator: "\n- "))
        }

        if !result.suggestions.isEmpty {
            sections.append("Öneriler:\n- " + result.suggestions.joined(separator: "\n- "))
        }

        return sections.joined(separator: "\n\n")
    }

    private func shareItems() -> [Any] {
        var items: [Any] = [shareSummary]
        let fileManager = FileManager.default

        if let videoShareURL = shareableCopy(of: session.analysisResult.videoPath, fileManager: fileManager) {
            items.append(videoShareURL)
        } else if let thumbShareURL = shareableCopy(of: session.analysisResult.videoThumbnailPath, fileManager: fileManager) {
            items.append(thumbShareURL)
        }

        return items
    }

    private func shareableCopy(of path: String?, fileManager: FileManager) -> URL? {
        guard let path else { return nil }
        let sourceURL = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: sourceURL.path) else { return nil }

        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension)

        do {
            if fileManager.fileExists(atPath: tempURL.path) {
                try fileManager.removeItem(at: tempURL)
            }
            try fileManager.copyItem(at: sourceURL, to: tempURL)
            return tempURL
        } catch {
            Configuration.log("Failed to prepare share item: \(error)", category: .storage, level: .error)
            return nil
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Score Card Component
struct ScoreCard: View {
    let result: AnalysisResult

    var body: some View {
        VStack(spacing: 24) {
            // Score Circle
            ZStack {
                // Background circle with glass effect
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 14)
                    .frame(width: 170, height: 170)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(result.score) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [result.scoreColor, result.scoreColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: result.scoreColor.opacity(0.5), radius: 10)

                VStack(spacing: 4) {
                    Text("\(result.score)")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)

                    Text("/ 100")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }

            // Score Level Badge
            Text(result.scoreLevel.displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .vibrantGlass(tint: result.scoreColor, cornerRadius: 20)

            // Date
            Text(result.timestamp, style: .date)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
        }
        .padding(24)
        .vibrantGlass(tint: result.scoreColor.opacity(0.3), cornerRadius: 20)
    }

}

// MARK: - Feedback Section Component
struct FeedbackSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            // Content
            Text(content)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Bullet List Section Component
struct BulletListSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            // Items
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(color)
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)

                        Text(items[index])
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    NavigationStack(path: $path) {
        AnalysisResultView(
            session: .mock,
            navigationPath: $path
        )
    }
}
