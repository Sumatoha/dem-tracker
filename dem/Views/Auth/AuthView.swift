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
                VStack(spacing: 24) {
                    Image("DemLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    VStack(spacing: 8) {
                        Text(L.Auth.welcomeTitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(L.Auth.welcomeSubtitle)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
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

                    Text(L.Auth.termsAgreement)
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
        .alert(L.Common.error, isPresented: $viewModel.showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? L.Common.error)
        }
    }
}

#Preview {
    AuthView()
}
