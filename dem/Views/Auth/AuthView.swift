import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.primaryAccent)
                            .frame(width: 16, height: 16)

                        Text("dem")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }

                    Text("Ваш путь к свободе от никотина")
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Apple Sign In Button
                VStack(spacing: 16) {
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        viewModel.handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(16)

                    Text("Продолжая, вы соглашаетесь с условиями использования")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, 48)
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
    AuthView()
}
