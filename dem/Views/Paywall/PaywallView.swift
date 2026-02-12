import SwiftUI
import StoreKit

// Модель для отображения плана (работает и с реальными продуктами, и с моками)
struct SubscriptionPlanDisplay: Identifiable {
    let id: SubscriptionManager.ProductID
    let title: String
    let subtitle: String?
    let price: String
    let pricePerMonth: String?
    let discount: String?
    let isRecommended: Bool
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject private var supabaseManager: SupabaseManager

    @State private var selectedPlan: SubscriptionManager.ProductID = .semiannual
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTerms = false
    @State private var showPrivacy = false

    let onSubscribed: () -> Void
    let onStartTrial: () -> Void

    // Stats from cache and profile

    /// Количество полных завершённых дней (сегодня НЕ считается)
    private var fullCompletedDays: Int {
        guard let profile = supabaseManager.currentProfile,
              let createdAt = profile.createdAt else {
            return 0
        }
        let calendar = Calendar.current
        let startOfCreation = calendar.startOfDay(for: createdAt)
        let startOfToday = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: startOfCreation, to: startOfToday).day ?? 0
        return max(0, days)
    }

    /// Сколько сигарет выкурено за все полные дни (без сегодня)
    private var actualSmoked: Int {
        guard let allLogs = CacheManager.shared.getCachedAllLogs() else { return 0 }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Фильтруем только логи ДО сегодняшнего дня
        let logsBeforeToday = allLogs.filter { log in
            guard let logDate = log.createdAt else { return false }
            return logDate < startOfToday
        }
        return logsBeforeToday.count
    }

    /// Сколько сигарет должен был выкурить за полные дни (baseline × дней)
    private var expectedSmoked: Int {
        guard let profile = supabaseManager.currentProfile else { return 0 }
        return profile.safeBaselinePerDay * fullCompletedDays
    }

    /// На сколько сигарет меньше выкурено (может быть отрицательным, но показываем 0)
    private var cigarettesReduced: Int {
        return max(0, expectedSmoked - actualSmoked)
    }

    /// Сколько денег сэкономлено
    private var savedMoney: Int {
        guard let profile = supabaseManager.currentProfile else { return 0 }
        return Int(Double(cigarettesReduced) * profile.pricePerUnit)
    }

    /// Для отображения в кружке прогресса
    private var daysUsingApp: Int {
        fullCompletedDays
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            Haptics.selection()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.cardFill)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Layout.horizontalPadding)

                    // Motivational block
                    motivationalBlock

                    // Features
                    featuresSection

                    // Subscription plans
                    plansSection

                    // CTA Button
                    ctaSection

                    // Restore + Legal links
                    legalSection

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .alert(L.Paywall.error, isPresented: $showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Motivational Block

    private var motivationalBlock: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cardFill, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: min(CGFloat(daysUsingApp) / 30.0, 1.0))
                    .stroke(Color.primaryAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(daysUsingApp)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(L.Paywall.days)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }

            Text(L.Paywall.dontLoseProgress)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(L.Paywall.subtitle)
                .font(.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Stats widget
            if savedMoney > 0 || cigarettesReduced > 0 {
                HStack(spacing: 24) {
                    if cigarettesReduced > 0 {
                        VStack(spacing: 4) {
                            Text("-\(cigarettesReduced)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.success)
                            Text(L.Paywall.cigarettesReduced)
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if savedMoney > 0 {
                        VStack(spacing: 4) {
                            Text("+\(savedMoney)₸")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.success)
                            Text(L.Paywall.moneySaved)
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "chart.line.uptrend.xyaxis", text: L.Paywall.featureStats)
            featureRow(icon: "bell.badge", text: L.Paywall.featureNotifications)
            featureRow(icon: "target", text: L.Paywall.featureGoals)
            featureRow(icon: "heart.fill", text: L.Paywall.featureHealth)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primaryAccent)
                .frame(width: 32)

            Text(text)
                .font(.bodyText)
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(plans) { plan in
                planCard(plan: plan)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var plans: [SubscriptionPlanDisplay] {
        // Если продукты загружены из StoreKit — используем их
        if let monthly = subscriptionManager.product(for: .monthly) {
            var result: [SubscriptionPlanDisplay] = []

            result.append(SubscriptionPlanDisplay(
                id: .monthly,
                title: L.Paywall.plan1Month,
                subtitle: nil,
                price: monthly.displayPrice,
                pricePerMonth: nil,
                discount: nil,
                isRecommended: false
            ))

            if let semiannual = subscriptionManager.product(for: .semiannual) {
                result.append(SubscriptionPlanDisplay(
                    id: .semiannual,
                    title: L.Paywall.plan6Months,
                    subtitle: L.Paywall.plan6MonthsSubtitle,
                    price: semiannual.displayPrice,
                    pricePerMonth: subscriptionManager.pricePerMonth(for: semiannual),
                    discount: "-17%",
                    isRecommended: true
                ))
            }

            if let annual = subscriptionManager.product(for: .annual) {
                result.append(SubscriptionPlanDisplay(
                    id: .annual,
                    title: L.Paywall.plan1Year,
                    subtitle: nil,
                    price: annual.displayPrice,
                    pricePerMonth: subscriptionManager.pricePerMonth(for: annual),
                    discount: nil,
                    isRecommended: false
                ))
            }

            return result
        }

        // Моковые данные для превью (пока не настроен App Store Connect)
        return [
            SubscriptionPlanDisplay(
                id: .monthly,
                title: L.Paywall.plan1Month,
                subtitle: nil,
                price: "$4.99",
                pricePerMonth: nil,
                discount: nil,
                isRecommended: false
            ),
            SubscriptionPlanDisplay(
                id: .semiannual,
                title: L.Paywall.plan6Months,
                subtitle: L.Paywall.plan6MonthsSubtitle,
                price: "$24.99",
                pricePerMonth: "$4.17",
                discount: "-17%",
                isRecommended: true
            ),
            SubscriptionPlanDisplay(
                id: .annual,
                title: L.Paywall.plan1Year,
                subtitle: nil,
                price: "$49.99",
                pricePerMonth: "$4.17",
                discount: nil,
                isRecommended: false
            )
        ]
    }

    private func planCard(plan: SubscriptionPlanDisplay) -> some View {
        let isSelected = selectedPlan == plan.id

        return Button {
            Haptics.selection()
            selectedPlan = plan.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        if plan.isRecommended {
                            Text(L.Paywall.bestChoice)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primaryAccent)
                                .cornerRadius(6)
                        }

                        if let discount = plan.discount {
                            Text(discount)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.success.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }

                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)

                    if let perMonth = plan.pricePerMonth {
                        Text("\(perMonth)/\(L.Paywall.month)")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(Layout.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .stroke(isSelected ? Color.primaryAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Кнопка пробного периода (только если ещё не использован)
            if subscriptionManager.canStartTrial {
                Button {
                    Haptics.success()
                    onStartTrial()
                    dismiss()
                } label: {
                    Text(L.Paywall.startTrial)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryAccent)
                        .cornerRadius(16)
                }

                // Разделитель
                HStack {
                    Rectangle()
                        .fill(Color.textMuted.opacity(0.3))
                        .frame(height: 1)
                    Text(L.Common.or)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                    Rectangle()
                        .fill(Color.textMuted.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 4)
            }

            // Кнопка подписки
            Button {
                Task {
                    await startSubscription()
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(subscriptionManager.canStartTrial ? L.Paywall.subscribeNow : L.Paywall.subscribe)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(subscriptionManager.canStartTrial ? .primaryAccent : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(subscriptionManager.canStartTrial ? Color.primaryAccent.opacity(0.15) : Color.primaryAccent)
                .cornerRadius(16)
            }
            .disabled(isProcessing)

            // Price disclaimer
            let selectedPlanDisplay = plans.first(where: { $0.id == selectedPlan })
            Text(L.Paywall.priceDisclaimer(selectedPlanDisplay?.price ?? "$24.99"))
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text(L.Paywall.restore)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 16) {
                Button {
                    showTerms = true
                } label: {
                    Text(L.Paywall.terms)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }

                Text("·")
                    .foregroundColor(.textMuted)

                Button {
                    showPrivacy = true
                } label: {
                    Text(L.Paywall.privacy)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Actions

    private func startSubscription() async {
        // Получаем реальный продукт из StoreKit
        guard let product = subscriptionManager.product(for: selectedPlan) else {
            // Если продукты не загружены (мок режим) — просто закрываем для превью
            errorMessage = L.Paywall.productsNotLoaded
            showError = true
            Haptics.error()
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                Haptics.success()
                // Update profile in Supabase
                await updateSubscriptionInProfile(productId: selectedPlan.rawValue)
                onSubscribed()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
        }
    }

    private func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }

        await subscriptionManager.restorePurchases()

        if subscriptionManager.isSubscribed {
            Haptics.success()
            onSubscribed()
            dismiss()
        } else {
            // No purchases found to restore
            errorMessage = L.Paywall.noPurchasesToRestore
            showError = true
            Haptics.error()
        }
    }

    private func updateSubscriptionInProfile(productId: String) async {
        do {
            let updates: [String: AnyEncodable] = [
                ColumnName.Profile.subscriptionStatus: AnyEncodable("active"),
                ColumnName.Profile.subscriptionProductId: AnyEncodable(productId)
            ]
            try await supabaseManager.updateProfile(updates)
        } catch {
            print("Failed to update subscription in profile: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        onSubscribed: {},
        onStartTrial: {}
    )
    .environmentObject(SupabaseManager.shared)
}
