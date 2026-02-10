import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let supabase = SupabaseManager.shared

    var isAuthenticated: Bool {
        supabase.currentUser != nil
    }

    var hasCompletedOnboarding: Bool {
        supabase.currentProfile?.onboardingDone ?? false
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showError(message: "Неверный тип авторизации")
                return
            }

            Task {
                await signInWithApple(credential: credential)
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(message: "Ошибка авторизации: \(error.localizedDescription)")
            }
        }
    }

    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.signInWithApple(credential: credential)
            Haptics.success()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.signOut()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
        Haptics.error()
    }
}
