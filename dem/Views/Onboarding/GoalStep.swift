import SwiftUI

struct GoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text("Какая цель?")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text("Выберите цель, которая наиболее точно описывает ваши намерения.")
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Goal type cards
            VStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    GoalTypeCard(
                        type: type,
                        isSelected: viewModel.selectedGoalType == type
                    ) {
                        viewModel.selectGoalType(type)
                    }
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Goal per day picker (for reduce)
            if viewModel.selectedGoalType == .reduce {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ДНЕВНОЙ ЛИМИТ")
                        .font(.sectionLabel)
                        .kerning(1)
                        .foregroundColor(.textMuted)

                    HStack {
                        Button {
                            Haptics.light()
                            if viewModel.goalPerDay > 1 {
                                viewModel.goalPerDay -= 1
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

                        Text("\(viewModel.goalPerDay)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primaryAccent)
                            .contentTransition(.numericText())

                        Text("шт./день")
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Button {
                            Haptics.light()
                            if viewModel.goalPerDay < viewModel.baselinePerDay {
                                viewModel.goalPerDay += 1
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

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                Button {
                    viewModel.nextStep()
                } label: {
                    Text("ПРОДОЛЖИТЬ")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep4))
                .disabled(!viewModel.canProceedStep4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.selectedGoalType)
    }
}

// MARK: - Goal Type Card

struct GoalTypeCard: View {
    let type: GoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
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
    GoalStep(viewModel: OnboardingViewModel())
        .background(Color.appBackground)
}
