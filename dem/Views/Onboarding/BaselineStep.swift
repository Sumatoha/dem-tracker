import SwiftUI

struct BaselineStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text(L.Onboarding.currentLevel)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text(L.Onboarding.baselineDescription)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Input cards
            VStack(spacing: 16) {
                // Per day card
                BaselineInputCard(
                    title: L.Onboarding.howManyPerDay,
                    value: $viewModel.baselinePerDay,
                    suffix: L.Units.pieces,
                    range: 1...60
                )

                // Pack price card
                BaselineInputCard(
                    title: L.Onboarding.packPriceLabel,
                    value: $viewModel.packPrice,
                    suffix: L.Units.tenge,
                    range: 50...5000,
                    step: 50
                )

                // Sticks in pack card
                BaselineInputCard(
                    title: L.Onboarding.inPack,
                    value: $viewModel.sticksInPack,
                    suffix: L.Units.pieces,
                    range: 10...40
                )
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                Button {
                    Haptics.selection()
                    viewModel.nextStep()
                } label: {
                    Text(L.Onboarding.continueButton)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep3))
                .disabled(!viewModel.canProceedStep3)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Baseline Input Card

struct BaselineInputCard: View {
    let title: String
    @Binding var value: Int
    let suffix: String
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.sectionLabel)
                .kerning(1)
                .foregroundColor(.textMuted)

            HStack {
                Button {
                    Haptics.light()
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Circle()
                        .fill(Color.cardFill)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.textPrimary)
                        }
                }
                .pressEffect()

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .contentTransition(.numericText())

                    Text(suffix)
                        .font(.cardValue)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Button {
                    Haptics.light()
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Circle()
                        .fill(Color.cardFill)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.textPrimary)
                        }
                }
                .pressEffect()
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(Layout.cardShadowOpacity), radius: Layout.cardShadowRadius, y: 1)
    }
}

#Preview {
    BaselineStep(viewModel: OnboardingViewModel())
        .background(Color.appBackground)
}
