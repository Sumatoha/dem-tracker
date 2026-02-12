import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String?
    var productType: ProductType?
    var baselinePerDay: Int?
    var packPrice: Int?
    var sticksInPack: Int?
    var goalType: GoalType?
    var goalPerDay: Int?
    var goalDate: Date?
    var onboardingDone: Bool?
    let createdAt: Date?
    var updatedAt: Date?

    // Program fields
    var programType: String?
    var programStartValue: Int?
    var programTargetValue: Int?
    var programDurationMonths: Int?
    var programStartDate: Date?
    var notificationTime: String?
    var notificationsEnabled: Bool?

    // Subscription fields
    var subscriptionStatus: String? // active, expired, trial, none
    var subscriptionProductId: String?
    var subscriptionExpiresAt: Date?
    var trialStartedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case productType = "product_type"
        case baselinePerDay = "baseline_per_day"
        case packPrice = "pack_price"
        case sticksInPack = "sticks_in_pack"
        case goalType = "goal_type"
        case goalPerDay = "goal_per_day"
        case goalDate = "goal_date"
        case onboardingDone = "onboarding_done"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case programType = "program_type"
        case programStartValue = "program_start_value"
        case programTargetValue = "program_target_value"
        case programDurationMonths = "program_duration_months"
        case programStartDate = "program_start_date"
        case notificationTime = "notification_time"
        case notificationsEnabled = "notifications_enabled"
        case subscriptionStatus = "subscription_status"
        case subscriptionProductId = "subscription_product_id"
        case subscriptionExpiresAt = "subscription_expires_at"
        case trialStartedAt = "trial_started_at"
    }

    init(
        id: UUID,
        name: String? = nil,
        productType: ProductType? = nil,
        baselinePerDay: Int? = nil,
        packPrice: Int? = nil,
        sticksInPack: Int? = nil,
        goalType: GoalType? = nil,
        goalPerDay: Int? = nil,
        goalDate: Date? = nil,
        onboardingDone: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        programType: String? = nil,
        programStartValue: Int? = nil,
        programTargetValue: Int? = nil,
        programDurationMonths: Int? = nil,
        programStartDate: Date? = nil,
        notificationTime: String? = nil,
        notificationsEnabled: Bool? = nil,
        subscriptionStatus: String? = nil,
        subscriptionProductId: String? = nil,
        subscriptionExpiresAt: Date? = nil,
        trialStartedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.productType = productType
        self.baselinePerDay = baselinePerDay
        self.packPrice = packPrice
        self.sticksInPack = sticksInPack
        self.goalType = goalType
        self.goalPerDay = goalPerDay
        self.goalDate = goalDate
        self.onboardingDone = onboardingDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.programType = programType
        self.programStartValue = programStartValue
        self.programTargetValue = programTargetValue
        self.programDurationMonths = programDurationMonths
        self.programStartDate = programStartDate
        self.notificationTime = notificationTime
        self.notificationsEnabled = notificationsEnabled
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionProductId = subscriptionProductId
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.trialStartedAt = trialStartedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        productType = try container.decodeIfPresent(ProductType.self, forKey: .productType)
        baselinePerDay = try container.decodeIfPresent(Int.self, forKey: .baselinePerDay)
        packPrice = try container.decodeIfPresent(Int.self, forKey: .packPrice)
        sticksInPack = try container.decodeIfPresent(Int.self, forKey: .sticksInPack)
        goalType = try container.decodeIfPresent(GoalType.self, forKey: .goalType)
        goalPerDay = try container.decodeIfPresent(Int.self, forKey: .goalPerDay)
        onboardingDone = try container.decodeIfPresent(Bool.self, forKey: .onboardingDone)

        // Program fields
        programType = try container.decodeIfPresent(String.self, forKey: .programType)
        programStartValue = try container.decodeIfPresent(Int.self, forKey: .programStartValue)
        programTargetValue = try container.decodeIfPresent(Int.self, forKey: .programTargetValue)
        programDurationMonths = try container.decodeIfPresent(Int.self, forKey: .programDurationMonths)
        notificationTime = try container.decodeIfPresent(String.self, forKey: .notificationTime)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled)

        // Parse dates from ISO8601 strings
        if let dateString = try container.decodeIfPresent(String.self, forKey: .goalDate) {
            goalDate = Self.parseDate(dateString)
        } else {
            goalDate = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(dateString)
        } else {
            createdAt = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = Self.parseDate(dateString)
        } else {
            updatedAt = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .programStartDate) {
            programStartDate = Self.parseDate(dateString)
        } else {
            programStartDate = nil
        }

        // Subscription fields
        subscriptionStatus = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus)
        subscriptionProductId = try container.decodeIfPresent(String.self, forKey: .subscriptionProductId)

        if let dateString = try container.decodeIfPresent(String.self, forKey: .subscriptionExpiresAt) {
            subscriptionExpiresAt = Self.parseDate(dateString)
        } else {
            subscriptionExpiresAt = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .trialStartedAt) {
            trialStartedAt = Self.parseDate(dateString)
        } else {
            trialStartedAt = nil
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        // Try ISO8601 with fractional seconds (Supabase format)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        // Try date only (for goal_date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: string)
    }

    // Safe accessors with defaults
    var safeBaselinePerDay: Int { baselinePerDay ?? 10 }
    var safePackPrice: Int { packPrice ?? 250 }
    var safeSticksInPack: Int { sticksInPack ?? 20 }
    var safeOnboardingDone: Bool { onboardingDone ?? false }
    var safeNotificationsEnabled: Bool { notificationsEnabled ?? true }
    var safeNotificationTime: String { notificationTime ?? "22:00" }
    var safeSubscriptionStatus: String { subscriptionStatus ?? "none" }

    /// Check if user has active subscription or trial
    var hasActiveSubscription: Bool {
        let status = safeSubscriptionStatus
        if status == "active" {
            // Check if not expired
            if let expiresAt = subscriptionExpiresAt {
                return expiresAt > Date()
            }
            return true
        }
        if status == "trial" {
            // Check if trial not expired (14 days from start)
            if let trialStart = trialStartedAt {
                let trialEnd = Calendar.current.date(byAdding: .day, value: 14, to: trialStart) ?? trialStart
                return Date() < trialEnd
            }
        }
        return false
    }

    /// Проверка активной программы (quit или reduce)
    var hasProgramActive: Bool {
        guard let type = programType else { return false }
        return type == "quit" || type == "reduce"
    }

    var pricePerUnit: Double {
        let sticks = safeSticksInPack
        guard sticks > 0 else { return 0 }
        return Double(safePackPrice) / Double(sticks)
    }

    var nicotinePerUnit: Double {
        switch productType {
        case .cigarette: return 1.2
        case .iqos: return 0.5
        case .vape: return 0.8
        case .mix, .none: return 1.0
        }
    }
}

enum ProductType: String, Codable, CaseIterable {
    case cigarette
    case iqos
    case vape
    case mix

    var displayName: String {
        switch self {
        case .cigarette: return L.Profile.cigarettes
        case .iqos: return L.Profile.iqos
        case .vape: return L.Profile.vape
        case .mix: return L.Profile.mix
        }
    }

    var iconName: String {
        switch self {
        case .cigarette: return "flame.fill"
        case .iqos: return "heat.waves"
        case .vape: return "cloud.fill"
        case .mix: return "square.stack.fill"
        }
    }
}

enum GoalType: String, Codable, CaseIterable {
    case quit
    case reduce
    case observe

    var displayName: String {
        switch self {
        case .quit: return L.Onboarding.goalQuit
        case .reduce: return L.Onboarding.goalReduce
        case .observe: return L.Onboarding.goalObserve
        }
    }

    var subtitle: String {
        switch self {
        case .quit: return L.Onboarding.goalQuitDesc
        case .reduce: return L.Onboarding.goalReduceDesc
        case .observe: return L.Onboarding.goalObserveDesc
        }
    }
}
