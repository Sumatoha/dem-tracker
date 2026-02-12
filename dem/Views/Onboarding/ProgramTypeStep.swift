import SwiftUI

struct ProgramTypeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text(L.Onboarding.yourPlan)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text(L.Onboarding.planDescription)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Program type cards
            VStack(spacing: 12) {
                ForEach(OnboardingViewModel.ProgramType.allCases, id: \.self) { type in
                    ProgramTypeCard(
                        type: type,
                        isSelected: viewModel.selectedProgramType == type
                    ) {
                        viewModel.selectProgramType(type)
                    }
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Target value picker (for reduce only)
            if viewModel.selectedProgramType == .reduce {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L.Profile.targetPerDay)
                        .font(.sectionLabel)
                        .kerning(1)
                        .foregroundColor(.textMuted)

                    HStack {
                        Button {
                            Haptics.light()
                            if viewModel.programTargetValue > 1 {
                                viewModel.programTargetValue -= 1
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

                        Text("\(viewModel.programTargetValue)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primaryAccent)
                            .contentTransition(.numericText())

                        Text(L.Units.piecesPerDay)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Button {
                            Haptics.light()
                            if viewModel.programTargetValue < viewModel.baselinePerDay - 1 {
                                viewModel.programTargetValue += 1
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

                    Text("\(L.Program.current): \(viewModel.baselinePerDay) \(L.Units.piecesPerDay)")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
                .padding(20)
                .background(Color.cardBackground)
                .cornerRadius(Layout.cardCornerRadius)
                .shadow(color: .black.opacity(Layout.cardShadowOpacity), radius: Layout.cardShadowRadius, y: 1)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                Button {
                    viewModel.nextStep()
                } label: {
                    Text(L.Onboarding.continueButton)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep5))
                .disabled(!viewModel.canProceedStep5)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.selectedProgramType)
    }
}

// MARK: - Program Type Card

struct ProgramTypeCard: View {
    let type: OnboardingViewModel.ProgramType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.cardValue)
                        .foregroundColor(.textPrimary)

                    Text(type.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Circle()
                    .stroke(isSelected ? Color.primaryAccent : Color.textMuted, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(Color.primaryAccent)
                                .frame(width: 14, height: 14)
                        }
                    }
            }
            .padding(20)
            .background(isSelected ? Color.primaryAccent.opacity(0.05) : Color.cardFill)
            .cornerRadius(Layout.cardCornerRadius)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                        .stroke(Color.primaryAccent, lineWidth: 2)
                }
            }
        }
        .pressEffect()
    }
}

#Preview {
    ProgramTypeStep(viewModel: OnboardingViewModel())
        .background(Color.appBackground)
}
