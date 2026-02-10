import SwiftUI

struct BigLogButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 10) {
            Button(action: {
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.buttonBlack)
                        .frame(width: Layout.bigButtonSize, height: Layout.bigButtonSize)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)

                    // Cigarette icon - minimal outline
                    CigaretteIcon()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                }
            }
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

            Text("Записать")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textMuted)
        }
    }
}

// MARK: - Cigarette Icon Shape

struct CigaretteIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Simple cigarette outline
        let bodyHeight: CGFloat = 7
        let bodyWidth: CGFloat = width * 0.8
        let filterWidth: CGFloat = bodyWidth * 0.22

        let centerY = height / 2
        let startX = (width - bodyWidth) / 2

        // Full cigarette outline (single rounded rect)
        let fullRect = CGRect(
            x: startX,
            y: centerY - bodyHeight / 2,
            width: bodyWidth,
            height: bodyHeight
        )
        path.addRoundedRect(in: fullRect, cornerSize: CGSize(width: bodyHeight / 2, height: bodyHeight / 2))

        // Filter separator line
        let separatorX = startX + filterWidth
        path.move(to: CGPoint(x: separatorX, y: centerY - bodyHeight / 2))
        path.addLine(to: CGPoint(x: separatorX, y: centerY + bodyHeight / 2))

        return path
    }
}

#Preview {
    BigLogButton(action: {})
        .padding()
        .background(Color.appBackground)
}
