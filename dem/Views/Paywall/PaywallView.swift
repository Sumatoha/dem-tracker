import SwiftUI
import StoreKit

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

    let canDismiss: Bool
    let onSubscribed: () -> Void
    let onStartTrial: () -> Void

    init(
        canDismiss: Bool = true,
        onSubscribed: @escaping () -> Void,
        onStartTrial: @escaping () -> Void
    ) {
        self.canDismiss = canDismiss
        self.onSubscribed = onSubscribed
        self.onStartTrial = onStartTrial
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                if canDismiss {
                    HStack {
                        Spacer()
                        Button {
                            Haptics.selection()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(Color.cardFill)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero section
                        heroSection
                            .padding(.top, canDismiss ? 8 : 60)

                        // Trial button (if available)
                        if subscriptionManager.canStartTrial {
                            trialSection
                        }

                        // Plans
                        plansSection

                        // Subscribe button
                        subscribeSection

                        // Legal
                        legalSection

                        Spacer(minLength: 32)
                    }
                }
            }
        }
        .alert(L.Paywall.error, isPresented: $showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // App icon style
            ZStack {
                Circle()
                    .fill(Color.primaryAccent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.primaryAccent)
            }

            Text(L.Paywall.unlockPremium)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(L.Paywall.premiumSubtitle)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Features list compact
            VStack(spacing: 10) {
                featureRow(icon: "chart.bar.fill", text: L.Paywall.featureStats)
                featureRow(icon: "bell.badge.fill", text: L.Paywall.featureNotifications)
                featureRow(icon: "target", text: L.Paywall.featureGoals)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primaryAccent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.success)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Trial Section

    private var trialSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.success()
                onStartTrial()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.Paywall.startTrialTitle)
                            .font(.system(size: 17, weight: .semibold))
                        Text(L.Paywall.trialFree)
                            .font(.system(size: 13))
                            .opacity(0.9)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }

            // Divider
            HStack {
                Rectangle()
                    .fill(Color.textMuted.opacity(0.2))
                    .frame(height: 1)
                Text(L.Common.or)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                Rectangle()
                    .fill(Color.textMuted.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: 10) {
            ForEach(plans) { plan in
                planCard(plan: plan)
            }
        }
        .padding(.horizontal, 20)
    }

    private var plans: [SubscriptionPlanDisplay] {
        if let monthly = subscriptionManager.product(for: .monthly) {
            var result: [SubscriptionPlanDisplay] = []

            if let semiannual = subscriptionManager.product(for: .semiannual) {
                result.append(SubscriptionPlanDisplay(
                    id: .semiannual,
                    title: L.Paywall.plan6Months,
                    price: semiannual.displayPrice,
                    pricePerMonth: subscriptionManager.pricePerMonth(for: semiannual),
                    discount: "-17%",
                    isRecommended: true
                ))
            }

            result.append(SubscriptionPlanDisplay(
                id: .monthly,
                title: L.Paywall.plan1Month,
                price: monthly.displayPrice,
                pricePerMonth: nil,
                discount: nil,
                isRecommended: false
            ))

            if let annual = subscriptionManager.product(for: .annual) {
                result.append(SubscriptionPlanDisplay(
                    id: .annual,
                    title: L.Paywall.plan1Year,
                    price: annual.displayPrice,
                    pricePerMonth: subscriptionManager.pricePerMonth(for: annual),
                    discount: "-17%",
                    isRecommended: false
                ))
            }

            return result
        }

        // Mock data
        return [
            SubscriptionPlanDisplay(
                id: .semiannual,
                title: L.Paywall.plan6Months,
                price: "$24.99",
                pricePerMonth: "$4.17",
                discount: "-17%",
                isRecommended: true
            ),
            SubscriptionPlanDisplay(
                id: .monthly,
                title: L.Paywall.plan1Month,
                price: "$4.99",
                pricePerMonth: nil,
                discount: nil,
                isRecommended: false
            ),
            SubscriptionPlanDisplay(
                id: .annual,
                title: L.Paywall.plan1Year,
                price: "$34.99",
                pricePerMonth: "$2.92",
                discount: "-17%",
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
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.primaryAccent : Color.textMuted.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.primaryAccent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)

                        if plan.isRecommended {
                            Text(L.Paywall.popular)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.primaryAccent)
                                .cornerRadius(4)
                        }

                        if let discount = plan.discount {
                            Text(discount)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.success)
                        }
                    }

                    if let perMonth = plan.pricePerMonth {
                        Text("\(perMonth)/\(L.Paywall.month)")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Text(plan.price)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Subscribe Section

    private var subscribeSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await startSubscription()
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: subscriptionManager.canStartTrial ? .primaryAccent : .white))
                    } else {
                        Text(L.Paywall.subscribe)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(subscriptionManager.canStartTrial ? .primaryAccent : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(subscriptionManager.canStartTrial ? Color.primaryAccent.opacity(0.15) : Color.primaryAccent)
                .cornerRadius(14)
            }
            .disabled(isProcessing)

            let selectedPlanDisplay = plans.first(where: { $0.id == selectedPlan })
            Text(L.Paywall.priceDisclaimer(selectedPlanDisplay?.price ?? "$24.99"))
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text(L.Paywall.restore)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 12) {
                Button { showTerms = true } label: {
                    Text(L.Paywall.terms)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Text("·").foregroundColor(.textMuted)

                Button { showPrivacy = true } label: {
                    Text(L.Paywall.privacy)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Actions

    private func startSubscription() async {
        guard let product = subscriptionManager.product(for: selectedPlan) else {
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

// MARK: - Plan Display Model

struct SubscriptionPlanDisplay: Identifiable {
    let id: SubscriptionManager.ProductID
    let title: String
    let price: String
    let pricePerMonth: String?
    let discount: String?
    let isRecommended: Bool
}

// MARK: - Preview

#Preview {
    PaywallView(
        canDismiss: true,
        onSubscribed: {},
        onStartTrial: {}
    )
    .environmentObject(SupabaseManager.shared)
}
