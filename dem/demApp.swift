import SwiftUI

@main
struct demApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(supabaseManager)
        }
    }
}

// MARK: - Root View (Auth Routing)

struct RootView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager

    @State private var isCheckingAuth = true

    /// Computed property - показывать онбординг только если профиль загружен и onboarding_done = false
    private var shouldShowOnboarding: Bool {
        guard let profile = supabaseManager.currentProfile else {
            return false // Профиль не загружен - не показываем онбординг
        }
        return !profile.safeOnboardingDone
    }

    /// Профиль ещё загружается (юзер есть, профиля нет)
    private var isLoadingProfile: Bool {
        supabaseManager.currentUser != nil && supabaseManager.currentProfile == nil
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if isCheckingAuth || isLoadingProfile {
                splashView
                    .transition(.opacity)
            } else if supabaseManager.currentUser == nil {
                AuthView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else if shouldShowOnboarding {
                OnboardingContainerView {
                    // После онбординга профиль обновится автоматически
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else {
                MainTabView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isCheckingAuth)
        .animation(.easeInOut(duration: 0.25), value: supabaseManager.currentUser?.id)
        .animation(.easeInOut(duration: 0.25), value: supabaseManager.currentProfile?.safeOnboardingDone)
        .task {
            await checkAuthState()
        }
    }

    private var splashView: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 20, height: 20)

                    Text("dem")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.textPrimary)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryAccent))
            }
        }
    }

    private func checkAuthState() async {
        // Small delay for splash screen
        try? await Task.sleep(nanoseconds: 500_000_000)

        await supabaseManager.checkSession()

        withAnimation(.easeOut(duration: 0.3)) {
            isCheckingAuth = false
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SupabaseManager.shared)
}
