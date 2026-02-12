import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Product IDs - must match App Store Connect
    enum ProductID: String, CaseIterable {
        case monthly = "com.dem.monthly"
        case semiannual = "com.dem.halfyear"
        case annual = "com.dem.yearly"

        var sortOrder: Int {
            switch self {
            case .monthly: return 0
            case .semiannual: return 1
            case .annual: return 2
            }
        }
    }

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    /// Indicates subscription status has been checked (StoreKit sync complete)
    @Published private(set) var isReady = false

    // Trial tracking
    @Published var trialStartDate: Date?
    @Published var hasUsedTrial: Bool = false

    // MARK: - Computed Properties

    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// User has never started a trial - eligible for free trial
    var canStartTrial: Bool {
        trialStartDate == nil && !hasUsedTrial
    }

    /// Trial was started but has expired (14 days passed)
    var trialHasExpired: Bool {
        guard let startDate = trialStartDate else { return false }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
        return Date() >= trialEndDate
    }

    var isInTrialPeriod: Bool {
        guard let startDate = trialStartDate else { return false }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
        return Date() < trialEndDate && !hasUsedTrial
    }

    var trialDaysRemaining: Int {
        guard let startDate = trialStartDate else { return 0 }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, days)
    }

    var hasAccess: Bool {
        isSubscribed || isInTrialPeriod
    }

    /// Subscription state for UI display
    enum SubscriptionState {
        case subscribed
        case inTrial(daysRemaining: Int)
        case trialExpired
        case noSubscription
    }

    var subscriptionState: SubscriptionState {
        if isSubscribed {
            return .subscribed
        } else if isInTrialPeriod {
            return .inTrial(daysRemaining: trialDaysRemaining)
        } else if trialHasExpired {
            return .trialExpired
        } else {
            return .noSubscription
        }
    }

    // MARK: - Init

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        loadTrialData()
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
            isReady = true
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Trial Management

    private let trialStartKey = "subscription_trial_start"
    private let trialUsedKey = "subscription_trial_used"

    private func loadTrialData() {
        if let startTimestamp = UserDefaults.standard.object(forKey: trialStartKey) as? TimeInterval {
            trialStartDate = Date(timeIntervalSince1970: startTimestamp)
        }
        hasUsedTrial = UserDefaults.standard.bool(forKey: trialUsedKey)
    }

    func startTrial() {
        guard trialStartDate == nil else { return }
        let now = Date()
        trialStartDate = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: trialStartKey)
    }

    func endTrial() {
        hasUsedTrial = true
        UserDefaults.standard.set(true, forKey: trialUsedKey)
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
                .sorted { ProductID(rawValue: $0.id)?.sortOrder ?? 0 < ProductID(rawValue: $1.id)?.sortOrder ?? 0 }
        } catch {
            self.error = error.localizedDescription
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            endTrial() // Trial ends when user subscribes
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        self.purchasedProductIDs = purchased
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func pricePerMonth(for product: Product) -> String? {
        guard let id = ProductID(rawValue: product.id) else { return nil }

        let price = product.price as Decimal
        let months: Decimal

        switch id {
        case .monthly:
            return nil // Don't show for monthly
        case .semiannual:
            months = 6
        case .annual:
            months = 12
        }

        let perMonth = price / months
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale

        return formatter.string(from: perMonth as NSDecimalNumber)
    }

    enum StoreError: Error {
        case failedVerification
    }
}

// MARK: - Subscription Plan Model

struct SubscriptionPlan: Identifiable {
    let id: SubscriptionManager.ProductID
    let product: Product
    let title: String
    let subtitle: String?
    let discount: String?
    let isRecommended: Bool
    let pricePerMonth: String?

    var price: String {
        product.displayPrice
    }
}
