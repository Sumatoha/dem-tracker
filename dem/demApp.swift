import SwiftUI
import UserNotifications
import StoreKit

@main
struct demApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(supabaseManager)
                .environmentObject(subscriptionManager)
        }
    }
}

// MARK: - Root View (Auth Routing)

struct RootView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var isCheckingAuth = true
    @State private var showPaywallOnboarding = false
    @State private var showPaywall = false
    @State private var hasCheckedPaywallThisSession = false

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

    /// Ждём пока SubscriptionManager проверит подписку
    private var isWaitingForSubscription: Bool {
        !subscriptionManager.isReady
    }

    /// Проверяет нужно ли показывать paywall
    private var needsPaywall: Bool {
        subscriptionManager.isReady && !subscriptionManager.hasAccess
    }

    /// Триал истёк и подписка не куплена - блокируем приложение
    private var shouldBlockApp: Bool {
        subscriptionManager.isReady && subscriptionManager.trialHasExpired && !subscriptionManager.isSubscribed
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if isCheckingAuth || isLoadingProfile || isWaitingForSubscription {
                splashView
                    .transition(.opacity)
            } else if supabaseManager.currentUser == nil {
                AuthView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else if shouldShowOnboarding {
                OnboardingContainerView {
                    // После онбординга проверяем подписку
                    checkAndShowPaywallOnce()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else {
                MainTabView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                    .task {
                        await requestNotificationPermission()
                    }
                    .onAppear {
                        // Показываем paywall ОДИН РАЗ при входе если нет доступа
                        checkAndShowPaywallOnce()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isCheckingAuth)
        .animation(.easeInOut(duration: 0.25), value: supabaseManager.currentUser?.id)
        .animation(.easeInOut(duration: 0.25), value: supabaseManager.currentProfile?.safeOnboardingDone)
        .task {
            await checkAuthState()
        }
        .onChange(of: subscriptionManager.trialHasExpired) { _, hasExpired in
            // Если триал истёк и нет подписки - блокируем приложение
            if hasExpired && !subscriptionManager.isSubscribed && !showPaywall {
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywallOnboarding) {
            PaywallOnboardingView {
                showPaywallOnboarding = false
                // После онбординга показываем paywall
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(
                canDismiss: !shouldBlockApp,
                onSubscribed: {
                    showPaywall = false
                },
                onStartTrial: {
                    subscriptionManager.startTrial()
                    showPaywall = false
                }
            )
            .interactiveDismissDisabled(shouldBlockApp)
        }
    }

    /// Показывает paywall только один раз за сессию
    private func checkAndShowPaywallOnce() {
        guard !hasCheckedPaywallThisSession else { return }
        hasCheckedPaywallThisSession = true

        if needsPaywall {
            // Если приложение заблокировано (триал истёк) - сразу показываем paywall
            if shouldBlockApp {
                showPaywall = true
            } else {
                // Иначе сначала показываем красивый онбординг, потом paywall
                showPaywallOnboarding = true
            }
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

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        // Only request if not determined yet
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }
}

#Preview {
    RootView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(SubscriptionManager.shared)
}
