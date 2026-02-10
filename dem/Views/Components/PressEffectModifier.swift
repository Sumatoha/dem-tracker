import SwiftUI

struct PressEffect: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func pressEffect() -> some View {
        modifier(PressEffect())
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLabel)
            .kerning(2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? Color.buttonBlack : Color.textMuted)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .kerning(1)
            .foregroundColor(.textMuted)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    var backgroundColor: Color = .cardBackground
    var showShadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(Layout.cardCornerRadius)
            .shadow(
                color: showShadow ? .black.opacity(Layout.cardShadowOpacity) : .clear,
                radius: showShadow ? Layout.cardShadowRadius : 0,
                x: 0,
                y: showShadow ? 1 : 0
            )
    }
}

extension View {
    func cardStyle(backgroundColor: Color = .cardBackground, showShadow: Bool = true) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, showShadow: showShadow))
    }
}
