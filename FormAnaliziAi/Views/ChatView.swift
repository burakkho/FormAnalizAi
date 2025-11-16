//
//  ChatView.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

struct ChatView: View {
    let session: AnalysisSession

    @Environment(GeminiService.self) private var geminiService
    @Environment(StorageService.self) private var storageService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ChatViewModel?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel = viewModel {
                VStack(spacing: 0) {
                    // Messages List
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: Constants.UI.mediumSpacing) {
                                // Welcome message if no chat history
                                if viewModel.messages.isEmpty {
                                    WelcomeChatMessage()
                                        .padding(.top, Constants.UI.largePadding)
                                }

                                // Messages
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Loading indicator
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .tint(.white)

                                        Text("AI düşünüyor...")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, Constants.UI.mediumPadding)
                                }
                            }
                            .padding()
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Input Area
                    HStack(spacing: Constants.UI.smallPadding) {
                        TextField("Soru sorun...", text: Binding(
                            get: { viewModel.inputText },
                            set: { viewModel.inputText = $0 }
                        ), axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(Constants.UI.smallPadding)
                            .background(AppColors.glassOverlay10)
                            .foregroundStyle(.white)
                            .cornerRadius(Constants.UI.smallCornerRadius)
                            .lineLimit(1...5)
                            .disabled(viewModel.isLoading)
                            .submitLabel(.send)
                            .onSubmit {
                                Task {
                                    await viewModel.sendMessage()
                                }
                            }

                        Button {
                            Task {
                                await viewModel.sendMessage()
                            }
                        } label: {
                            Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.canSend ? .white : .gray)
                        }
                        .disabled(!viewModel.canSend)
                    }
                    .padding()
                    .background(.black)
                }
            }
        }
        .navigationTitle("Sohbet")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Initialize ViewModel lazily
            if viewModel == nil {
                viewModel = ChatViewModel(
                    session: session,
                    geminiService: geminiService,
                    storageService: storageService
                )
            }
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

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Group {
                    if message.isUser {
                        // User message: white gradient
                        Text(message.content)
                            .font(.body)
                            .foregroundStyle(.black)
                            .padding(Constants.UI.smallPadding + 2)
                            .background(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(Constants.UI.cornerRadius)
                            .shadow(color: AppColors.glassOverlay20, radius: 8, x: 0, y: 4)
                    } else {
                        // Assistant message: glass effect
                        Text(message.content)
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(Constants.UI.smallPadding + 2)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [AppColors.glassBorder, AppColors.glassOverlay10],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(Constants.UI.glassOverlay10), radius: 8, x: 0, y: 4)
                    }
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
            }

            if message.isAssistant {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Welcome Chat Message
struct WelcomeChatMessage: View {
    var body: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.primaryBlue)

            Text("Soru Sorun")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Analiz sonucunuz hakkında sorularınızı yanıtlayabilirim")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ChatView(session: .mock)
            .environment(GeminiService())
            .environment(StorageService())
    }
}
