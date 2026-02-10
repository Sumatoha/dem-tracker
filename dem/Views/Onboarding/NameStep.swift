import SwiftUI

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text("Привет!")
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text("Как тебя зовут? Это имя будет отображаться в твоём профиле.")
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("ИМЯ ИЛИ НИКНЕЙМ")
                    .font(.sectionLabel)
                    .kerning(1)
                    .foregroundColor(.textMuted)

                TextField("Введите имя", text: $viewModel.userName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(16)
                    .background(Color.cardFill)
                    .cornerRadius(12)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if viewModel.canProceedStep1 {
                            viewModel.nextStep()
                        }
                    }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            Spacer()

            // Bottom section
            VStack(spacing: 16) {
                Button {
                    isNameFocused = false
                    Haptics.selection()
                    viewModel.nextStep()
                } label: {
                    Text("ПРОДОЛЖИТЬ")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canProceedStep1))
                .disabled(!viewModel.canProceedStep1)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
        .onTapGesture {
            isNameFocused = false
        }
    }
}

#Preview {
    NameStep(viewModel: OnboardingViewModel())
        .background(Color.appBackground)
}
