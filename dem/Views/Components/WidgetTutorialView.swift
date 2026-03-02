import SwiftUI

struct WidgetTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenWidgetTutorial") private var hasSeenTutorial = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        hasSeenTutorial = true
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.cardFill)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()
                    .frame(height: 20)

                // Widget preview mockup
                widgetPreview
                    .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 32)

                // Title
                Text(L.Widget.tutorialTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: 12)

                Text(L.Widget.tutorialSubtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 36)

                // Visual steps
                VStack(spacing: 20) {
                    stepRow(
                        icon: "hand.tap.fill",
                        number: "1",
                        text: L.Widget.step1
                    )
                    stepRow(
                        icon: "plus.circle.fill",
                        number: "2",
                        text: L.Widget.step2
                    )
                    stepRow(
                        icon: "square.grid.2x2.fill",
                        number: "3",
                        text: L.Widget.step3
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Got it button
                Button {
                    Haptics.selection()
                    hasSeenTutorial = true
                    dismiss()
                } label: {
                    Text(L.Widget.gotIt)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryAccent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Widget Preview

    private var widgetPreview: some View {
        ZStack {
            // Phone frame outline (subtle)
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.textMuted.opacity(0.3), lineWidth: 2)
                .frame(height: 200)

            // Widget inside phone
            HStack(spacing: 16) {
                // Small widget preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.96, green: 0.95, blue: 0.94))
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)

                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.primaryAccent.opacity(0.2), lineWidth: 2)
                                .frame(width: 36, height: 36)

                            Circle()
                                .fill(Color.buttonBlack)
                                .frame(width: 28, height: 28)

                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Text("7")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)

                        Text("СЕГОДНЯ")
                            .font(.system(size: 6, weight: .semibold))
                            .foregroundColor(.textMuted)
                    }
                }

                // Tap indicator
                VStack(spacing: 8) {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.primaryAccent)

                    Text(L.Widget.tap)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primaryAccent)
                }
            }
        }
    }

    // MARK: - Step Row

    private func stepRow(icon: String, number: String, text: String) -> some View {
        HStack(spacing: 16) {
            // Icon with number badge
            ZStack {
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.primaryAccent)

                // Number badge
                Text(number)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.buttonBlack)
                    .clipShape(Circle())
                    .offset(x: 18, y: -18)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .lineLimit(2)

            Spacer()
        }
    }
}

#Preview {
    WidgetTutorialView()
}
