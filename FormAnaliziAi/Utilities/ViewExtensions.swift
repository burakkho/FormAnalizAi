//
//  ViewExtensions.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI

// MARK: - Typography Extensions
extension Font {
    // MARK: - App Title & Display
    static let appTitle = Font.system(size: 36, weight: .bold)
    static let scoreDisplay = Font.system(size: 56, weight: .bold)
    static let iconLarge = Font.system(size: 100)
    static let iconMedium = Font.system(size: 60)

    // MARK: - Headers
    static let sectionHeader = Font.system(size: 24, weight: .semibold)
    static let cardHeader = Font.system(size: 20, weight: .semibold)

    // MARK: - Body & Content
    static let bodyRegular = Font.system(size: 17)
    static let bodyBold = Font.system(size: 17, weight: .bold)
    static let bodyMedium = Font.system(size: 17, weight: .medium)

    // MARK: - Metadata & Labels
    static let metadataText = Font.system(size: 14)
    static let smallText = Font.system(size: 12)
    static let tinyText = Font.system(size: 10)
}

// MARK: - App Colors
enum AppColors {
    // MARK: - Semantic Colors
    static let primaryBlue = Color("PrimaryBlue")
    static let successGreen = Color("SuccessGreen")
    static let warningOrange = Color("WarningOrange")
    static let errorRed = Color("ErrorRed")

    // MARK: - Glass Overlay Colors
    static let glassOverlay10 = Color("GlassOverlay10")
    static let glassOverlay20 = Color("GlassOverlay20")
    static let glassOverlay30 = Color("GlassOverlay30")
    static let glassBorder = Color("GlassBorder")
}

// MARK: - View Extensions
extension View {
    // MARK: - Liquid Glass Effects (iOS 26 Design Language)

    /// Applies Liquid Glass effect with ultra-thin material
    func liquidGlass(cornerRadius: CGFloat = Constants.UI.cornerRadius) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppColors.glassBorder,
                                AppColors.glassOverlay10,
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(Constants.UI.glassOverlay10), radius: 10, x: 0, y: 5)
            .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: -1)
    }

    /// Applies thicker glass effect for cards
    func glassCard(cornerRadius: CGFloat = Constants.UI.cornerRadius) -> some View {
        self
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                AppColors.glassOverlay10
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(Constants.UI.glassOverlay20), radius: 15, x: 0, y: 8)
            .shadow(color: AppColors.glassOverlay10, radius: 2, x: 0, y: -2)
    }

    /// Applies vibrant glass effect with color tint
    func vibrantGlass(tint: Color, cornerRadius: CGFloat = Constants.UI.cornerRadius) -> some View {
        self
            .background(
                ZStack {
                    tint.opacity(0.15)
                        .blur(radius: 20)
                    Color.clear
                        .background(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.5),
                                tint.opacity(Constants.UI.glassOverlay20),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: tint.opacity(Constants.UI.glassOverlay30), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(Constants.UI.glassOverlay10), radius: 5, x: 0, y: 5)
    }

    /// Applies frosted glass effect for overlays
    func frostedGlass(cornerRadius: CGFloat = Constants.UI.cornerRadius) -> some View {
        self
            .background(
                Color.white.opacity(0.05)
                    .background(.regularMaterial)
                    .blur(radius: 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppColors.glassOverlay20, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    // MARK: - Shimmer Effect (Loading)
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }

    // MARK: - Bounce Animation
    func bounceAnimation() -> some View {
        self.modifier(BounceModifier())
    }

    // MARK: - Slide In Animation
    func slideInAnimation(delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(delay: delay))
    }

    // MARK: - Haptic Feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            HapticManager.shared.impact(style)
        }
    }

    func hapticSuccess() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.notification(.success)
                }
        )
    }

    func hapticWarning() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.notification(.warning)
                }
        )
    }

    func hapticError() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.notification(.error)
                }
        )
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

// MARK: - Bounce Modifier
struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .spring(response: 0.3, dampingFraction: 0.6)
                ) {
                    scale = 1.1
                }
                withAnimation(
                    .spring(response: 0.3, dampingFraction: 0.6)
                    .delay(0.2)
                ) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Slide In Modifier
struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.5)
                    .delay(delay)
                ) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Button Styles

/// Primary button style with white gradient background
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: Constants.UI.buttonHeight)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
            )
            .foregroundStyle(Color.black)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: AppColors.glassBorder, radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(Constants.UI.glassOverlay20), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Animation.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style with glass overlay
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: Constants.UI.buttonHeight)
            .background(AppColors.glassOverlay10)
            .foregroundStyle(Color.white)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(AppColors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Animation.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

// MARK: - Reusable Badge Component

enum BadgeSize {
    case small
    case medium

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Constants.UI.smallBadgePaddingHorizontal
        case .medium: return Constants.UI.badgePaddingHorizontal
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return Constants.UI.smallBadgePaddingVertical
        case .medium: return Constants.UI.badgePaddingVertical
        }
    }
}

struct Badge: View {
    let icon: String?
    let text: String
    let color: Color
    let size: BadgeSize

    init(icon: String? = nil, text: String, color: Color, size: BadgeSize = .medium) {
        self.icon = icon
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(size == .small ? .caption : .subheadline)
            }

            Text(text)
                .font(size == .small ? .caption : .subheadline)
                .fontWeight(size == .small ? .medium : .bold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(color.opacity(Constants.UI.glassOverlay20))
        )
    }
}

// MARK: - Haptic Manager
@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()

    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
