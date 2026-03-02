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
                            .frame(width: 28, height: 28)
                            .background(Color.cardFill)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Widget preview
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 8)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.buttonBlack)
                                .frame(width: 50, height: 50)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Text("0")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(L.Widget.today)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()
                    .frame(height: 40)

                // Text
                VStack(spacing: 16) {
                    Text(L.Widget.tutorialTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L.Widget.tutorialSubtitle)
                        .font(.system(size: 17))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 32)

                // Steps
                VStack(alignment: .leading, spacing: 16) {
                    stepRow(number: "1", text: L.Widget.step1)
                    stepRow(number: "2", text: L.Widget.step2)
                    stepRow(number: "3", text: L.Widget.step3)
                }
                .padding(.horizontal, 32)

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

    private func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.primaryAccent)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)

            Spacer()
        }
    }
}

#Preview {
    WidgetTutorialView()
}
