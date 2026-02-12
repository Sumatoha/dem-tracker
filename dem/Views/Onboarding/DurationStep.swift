import SwiftUI

struct DurationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text(L.Onboarding.duration)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text(L.Onboarding.durationDescription)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Duration options in 2x2 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(OnboardingViewModel.ProgramDuration.allCases, id: \.self) { duration in
                    DurationCard(
                        duration: duration,
                        isSelected: viewModel.selectedDuration == duration
                    ) {
                        viewModel.selectDuration(duration)
                    }
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Custom duration picker
            if viewModel.selectedDuration == .custom {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L.Profile.programDuration)
                        .font(.sectionLabel)
                        .kerning(1)
                        .foregroundColor(.textMuted)

                    HStack {
                        Button {
                            Haptics.light()
                            if viewModel.customDurationMonths > 1 {
                                viewModel.customDurationMonths -= 1
                            }
                        } label: {
                            Circle()
                                .fill(Color.cardFill)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "minus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                }
                        }

                        Spacer()

                        Text("\(viewModel.customDurationMonths)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primaryAccent)
                            .contentTransition(.numericText())

                        Text(L.Onboarding.months)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Button {
                            Haptics.light()
                            if viewModel.customDurationMonths < 12 {
                                viewModel.customDurationMonths += 1
                            }
                        } label: {
                            Circle()
                                .fill(Color.cardFill)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                }
                        }
                    }
                }
                .padding(20)
                .background(Color.cardBackground)
                .cornerRadius(Layout.cardCornerRadius)
                .shadow(color: .black.opacity(Layout.cardShadowOpacity), radius: Layout.cardShadowRadius, y: 1)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Recommendation hint
            VStack(alignment: .leading, spacing: 8) {
                let recommendation = recommendedDuration()
                Text(L.Onboarding.recommendationText(viewModel.baselinePerDay, recommendation))
                    .font(.caption)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 24)

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                Button {
                    onComplete()
                } label: {
                    Text(L.Onboarding.start)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep6))
                .disabled(!viewModel.canProceedStep6)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.selectedDuration)
    }

    private func recommendedDuration() -> String {
        let baseline = viewModel.baselinePerDay
        if baseline > 15 {
            return "3-6 месяцев"
        } else if baseline > 8 {
            return "1-3 месяца"
        } else {
            return "1 месяц"
        }
    }
}

// MARK: - Duration Card

struct DurationCard: View {
    let duration: OnboardingViewModel.ProgramDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(duration.title)
                    .font(.cardValue)
                    .foregroundColor(.textPrimary)

                Text(duration.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(duration.isRecommended ? .primaryAccent : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.primaryAccent.opacity(0.05) : Color.cardFill)
            .cornerRadius(Layout.cardCornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .stroke(
                        isSelected ? Color.primaryAccent : (duration.isRecommended ? Color.primaryAccent.opacity(0.3) : Color.clear),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .pressEffect()
    }
}

#Preview {
    DurationStep(viewModel: OnboardingViewModel(), onComplete: {})
        .background(Color.appBackground)
}
