import SwiftUI

struct ProductTypeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text("Мой выбор")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text("Выберите основной источник никотина для точной настройки алгоритмов трекинга.")
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Product type cards
            VStack(spacing: 12) {
                ForEach([ProductType.cigarette, .iqos, .vape], id: \.self) { type in
                    ProductTypeCard(
                        type: type,
                        isSelected: viewModel.selectedProductType == type
                    ) {
                        viewModel.selectProductType(type)
                    }
                }
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
                    Text("ПРОДОЛЖИТЬ")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep2))
                .disabled(!viewModel.canProceedStep2)

                Text("ВЫ СМОЖЕТЕ ИЗМЕНИТЬ ЭТО ПОЗЖЕ")
                    .font(.system(size: 11, weight: .medium))
                    .kerning(1)
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Product Type Card

struct ProductTypeCard: View {
    let type: ProductType
    let isSelected: Bool
    let action: () -> Void

    private var iconColor: Color {
        if isSelected && type == .cigarette {
            return .primaryAccent
        }
        return isSelected ? .primaryAccent : .buttonBlack
    }

    private var iconBackgroundColor: Color {
        if isSelected && type == .cigarette {
            return .primaryAccent
        }
        return .buttonBlack
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ТИП")
                        .font(.sectionLabel)
                        .kerning(1)
                        .foregroundColor(.textMuted)

                    Text(type.displayName)
                        .font(.cardTitle)
                        .foregroundColor(.textPrimary)
                }

                Spacer()

                Circle()
                    .fill(isSelected && type == .cigarette ? Color.primaryAccent : Color.buttonBlack)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: type.iconName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
            }
            .padding(20)
            .background(Color.cardFill)
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
    ProductTypeStep(viewModel: OnboardingViewModel())
        .background(Color.appBackground)
}
