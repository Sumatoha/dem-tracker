import SwiftUI

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 12) {
                Text(L.Onboarding.hello)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text(L.Onboarding.nameDescription)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 32)

            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text(L.Onboarding.namePlaceholder.uppercased())
                    .font(.sectionLabel)
                    .kerning(1)
                    .foregroundColor(.textMuted)

                TextField(L.Onboarding.enterName, text: $viewModel.userName)
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
                    Text(L.Onboarding.continueButton)
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
