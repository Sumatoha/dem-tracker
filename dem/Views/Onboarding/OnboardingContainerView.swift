import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        if viewModel.currentStep > 1 {
                            viewModel.previousStep()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(viewModel.currentStep > 1 ? .textPrimary : .clear)
                    }
                    .disabled(viewModel.currentStep == 1)

                    Spacer()

                    Text(viewModel.progressText)
                        .font(.sectionLabel)
                        .kerning(3)
                        .foregroundColor(.textMuted)

                    Spacer()

                    // Invisible spacer for alignment
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 16)

                // Content - manual step switching for smoother animation
                ZStack {
                    switch viewModel.currentStep {
                    case 1:
                        NameStep(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 2:
                        ProductTypeStep(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 3:
                        BaselineStep(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 4:
                        GoalStep(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 5:
                        ProgramTypeStep(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 6:
                        DurationStep(viewModel: viewModel, onComplete: {
                            Task {
                                let success = await viewModel.completeOnboarding()
                                if success {
                                    onComplete()
                                }
                            }
                        })
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    default:
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
            }

            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Произошла ошибка")
        }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}
