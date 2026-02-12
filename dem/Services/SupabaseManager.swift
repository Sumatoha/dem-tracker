import Foundation
import Supabase
import AuthenticationServices

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isLoading = false

    private var isFetchingProfile = false

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
        // checkSession вызывается из RootView.task
    }

    // MARK: - Auth

    func checkSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            await fetchOrCreateProfile()
        } catch {
            currentUser = nil
            currentProfile = nil
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        isLoading = true
        defer { isLoading = false }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        currentUser = session.user
        await fetchOrCreateProfile()
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        currentProfile = nil
    }

    func deleteUserData() async throws {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        // Delete all smoking logs for this user
        try await client
            .from(TableName.logs)
            .delete()
            .eq(ColumnName.Log.userId, value: userId)
            .execute()

        // Delete profile
        try await client
            .from(TableName.profiles)
            .delete()
            .eq(ColumnName.Profile.id, value: userId)
            .execute()

        // Clear local cache
        CacheManager.shared.clearCache()
    }

    // MARK: - Profile

    /// ТОЛЬКО ЧИТАЕТ профиль из базы. НИКОГДА не создаёт и не перезаписывает.
    /// Профиль создаётся ТОЛЬКО в completeOnboarding при первом прохождении онбординга.
    func fetchOrCreateProfile() async {
        guard let userId = currentUser?.id else { return }

        // Prevent concurrent fetches
        guard !isFetchingProfile else { return }
        isFetchingProfile = true
        defer { isFetchingProfile = false }

        // Try to fetch existing profile - NEVER create or modify
        await fetchProfileOnly(userId: userId)
    }

    /// Загружает профиль из базы. Если не получилось — currentProfile = nil.
    /// НИКОГДА не записывает в базу.
    private func fetchProfileOnly(userId: UUID) async {
        // First try standard decode
        do {
            let profiles: [Profile] = try await client
                .from(TableName.profiles)
                .select()
                .eq(ColumnName.Profile.id, value: userId)
                .execute()
                .value

            if let profile = profiles.first {
                currentProfile = profile
                return
            }

            // Empty array - profile doesn't exist yet (new user)
            // Don't create - wait for onboarding to complete
            currentProfile = nil
        } catch {
            // Decode failed - try manual decode
            await fetchProfileManualDecode(userId: userId)
        }
    }

    /// Ручной декодинг профиля если стандартный не сработал.
    /// НИКОГДА не записывает в базу.
    private func fetchProfileManualDecode(userId: UUID) async {
        struct FlexibleProfile: Decodable {
            let id: UUID
            let name: String?
            let product_type: String?
            let baseline_per_day: Int?
            let pack_price: Int?
            let sticks_in_pack: Int?
            let goal_type: String?
            let goal_per_day: Int?
            let goal_date: String?
            let onboarding_done: Bool?
            let created_at: String?
            let updated_at: String?
            let program_type: String?
            let program_start_value: Int?
            let program_target_value: Int?
            let program_duration_months: Int?
            let program_start_date: String?
            let notification_time: String?
            let notifications_enabled: Bool?
        }

        do {
            let response = try await client
                .from(TableName.profiles)
                .select()
                .eq(ColumnName.Profile.id, value: userId)
                .execute()

            let decoder = JSONDecoder()
            if let profiles = try? decoder.decode([FlexibleProfile].self, from: response.data),
               let p = profiles.first {
                currentProfile = Profile(
                    id: p.id,
                    name: p.name,
                    productType: p.product_type.flatMap { ProductType(rawValue: $0) },
                    baselinePerDay: p.baseline_per_day,
                    packPrice: p.pack_price,
                    sticksInPack: p.sticks_in_pack,
                    goalType: p.goal_type.flatMap { GoalType(rawValue: $0) },
                    goalPerDay: p.goal_per_day,
                    goalDate: nil,
                    onboardingDone: p.onboarding_done,
                    createdAt: Date(),
                    updatedAt: Date(),
                    programType: p.program_type,
                    programStartValue: p.program_start_value,
                    programTargetValue: p.program_target_value,
                    programDurationMonths: p.program_duration_months,
                    programStartDate: nil,
                    notificationTime: p.notification_time,
                    notificationsEnabled: p.notifications_enabled
                )
            } else {
                // Profile doesn't exist - new user, wait for onboarding
                currentProfile = nil
            }
        } catch {
            // Network error - leave profile as nil
            currentProfile = nil
        }
    }

    func updateProfile(_ updates: [String: AnyEncodable]) async throws {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        var mutableUpdates = updates
        mutableUpdates[ColumnName.Profile.updatedAt] = AnyEncodable(Date())

        try await client
            .from(TableName.profiles)
            .update(mutableUpdates)
            .eq(ColumnName.Profile.id, value: userId)
            .execute()

        // Try to fetch updated profile, but don't fail if decode fails
        do {
            let profiles: [Profile] = try await client
                .from(TableName.profiles)
                .select()
                .eq(ColumnName.Profile.id, value: userId)
                .execute()
                .value

            if let profile = profiles.first {
                currentProfile = profile
            }
        } catch {
            // Keep existing profile if fetch fails
        }
    }

    func completeOnboarding(
        name: String?,
        productType: ProductType,
        baselinePerDay: Int,
        packPrice: Int,
        sticksInPack: Int,
        goalType: GoalType,
        goalPerDay: Int?,
        goalDate: Date?,
        programType: String? = nil,
        programStartValue: Int? = nil,
        programTargetValue: Int? = nil,
        programDurationMonths: Int? = nil,
        programStartDate: Date? = nil
    ) async throws {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        var profileData: [String: AnyEncodable] = [
            ColumnName.Profile.id: AnyEncodable(userId),
            ColumnName.Profile.name: AnyEncodable(name),
            ColumnName.Profile.productType: AnyEncodable(productType.rawValue),
            ColumnName.Profile.baselinePerDay: AnyEncodable(baselinePerDay),
            ColumnName.Profile.packPrice: AnyEncodable(packPrice),
            ColumnName.Profile.sticksInPack: AnyEncodable(sticksInPack),
            ColumnName.Profile.goalType: AnyEncodable(goalType.rawValue),
            ColumnName.Profile.onboardingDone: AnyEncodable(true),
            ColumnName.Profile.updatedAt: AnyEncodable(Date())
        ]

        if let goalPerDay = goalPerDay {
            profileData[ColumnName.Profile.goalPerDay] = AnyEncodable(goalPerDay)
        }

        if let goalDate = goalDate {
            profileData[ColumnName.Profile.goalDate] = AnyEncodable(goalDate)
        }

        // Program fields
        if let programType = programType {
            profileData[ColumnName.Profile.programType] = AnyEncodable(programType)
        }
        if let programStartValue = programStartValue {
            profileData[ColumnName.Profile.programStartValue] = AnyEncodable(programStartValue)
        }
        if let programTargetValue = programTargetValue {
            profileData[ColumnName.Profile.programTargetValue] = AnyEncodable(programTargetValue)
        }
        if let programDurationMonths = programDurationMonths {
            profileData[ColumnName.Profile.programDurationMonths] = AnyEncodable(programDurationMonths)
        }
        if let programStartDate = programStartDate {
            profileData[ColumnName.Profile.programStartDate] = AnyEncodable(programStartDate)
        }

        // Default notification settings
        profileData[ColumnName.Profile.notificationsEnabled] = AnyEncodable(true)
        profileData[ColumnName.Profile.notificationTime] = AnyEncodable("22:00")

        // Upsert to database
        try await client
            .from(TableName.profiles)
            .upsert(profileData, onConflict: ColumnName.Profile.id)
            .execute()

        // Update local profile immediately (don't fetch - avoid decode errors)
        currentProfile = Profile(
            id: userId,
            name: name,
            productType: productType,
            baselinePerDay: baselinePerDay,
            packPrice: packPrice,
            sticksInPack: sticksInPack,
            goalType: goalType,
            goalPerDay: goalPerDay,
            goalDate: goalDate,
            onboardingDone: true,
            createdAt: currentProfile?.createdAt ?? Date(),
            updatedAt: Date(),
            programType: programType,
            programStartValue: programStartValue,
            programTargetValue: programTargetValue,
            programDurationMonths: programDurationMonths,
            programStartDate: programStartDate,
            notificationTime: "22:00",
            notificationsEnabled: true
        )
    }

    // MARK: - Logs

    func createLog(trigger: TriggerType?) async throws {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        let profile = currentProfile ?? Profile(
            id: userId,
            name: nil,
            productType: .cigarette,
            baselinePerDay: 10,
            packPrice: 250,
            sticksInPack: 20,
            goalType: nil,
            goalPerDay: nil,
            goalDate: nil,
            onboardingDone: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let productType = profile.productType ?? .cigarette
        let price = Int(profile.pricePerUnit)
        let nicotine = profile.nicotinePerUnit

        let log: [String: AnyEncodable] = [
            ColumnName.Log.userId: AnyEncodable(userId),
            ColumnName.Log.productType: AnyEncodable(productType.rawValue),
            ColumnName.Log.trigger: AnyEncodable(trigger?.rawValue),
            ColumnName.Log.price: AnyEncodable(price),
            ColumnName.Log.nicotineMg: AnyEncodable(nicotine),
            ColumnName.Log.createdAt: AnyEncodable(Date())
        ]

        try await client
            .from(TableName.logs)
            .insert(log)
            .execute()
    }

    func fetchTodayLogs() async throws -> [SmokingLog] {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let logs: [SmokingLog] = try await client
            .from(TableName.logs)
            .select()
            .eq(ColumnName.Log.userId, value: userId)
            .gte(ColumnName.Log.createdAt, value: startOfDay.ISO8601Format())
            .order(ColumnName.Log.createdAt, ascending: false)
            .execute()
            .value

        return logs
    }

    func fetchLogsForDateRange(from: Date, to: Date) async throws -> [SmokingLog] {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        let logs: [SmokingLog] = try await client
            .from(TableName.logs)
            .select()
            .eq(ColumnName.Log.userId, value: userId)
            .gte(ColumnName.Log.createdAt, value: from.ISO8601Format())
            .lte(ColumnName.Log.createdAt, value: to.ISO8601Format())
            .order(ColumnName.Log.createdAt, ascending: false)
            .execute()
            .value

        return logs
    }

    func fetchWeeklyLogs() async throws -> [SmokingLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return []
        }

        return try await fetchLogsForDateRange(from: weekAgo, to: Date())
    }

    // MARK: - Cravings

    func createCraving(resisted: Bool, method: CravingMethod?, durationSeconds: Int?, trigger: String?) async throws {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        let craving: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId),
            "resisted": AnyEncodable(resisted),
            "method": AnyEncodable(method?.rawValue),
            "duration_seconds": AnyEncodable(durationSeconds),
            "trigger": AnyEncodable(trigger),
            "created_at": AnyEncodable(Date())
        ]

        try await client
            .from(TableName.cravings)
            .insert(craving)
            .execute()
    }

    // MARK: - Achievements

    func fetchAchievements() async throws -> [Achievement] {
        guard let userId = currentUser?.id else {
            throw DatabaseError.notAuthenticated
        }

        let achievements: [Achievement] = try await client
            .from(TableName.achievements)
            .select()
            .eq("user_id", value: userId)
            .order("unlocked_at", ascending: false)
            .execute()
            .value

        return achievements
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Не удалось получить токен авторизации"
        }
    }
}

enum DatabaseError: LocalizedError {
    case notAuthenticated
    case fetchFailed
    case insertFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Пользователь не авторизован"
        case .fetchFailed:
            return "Ошибка загрузки данных"
        case .insertFailed:
            return "Ошибка сохранения данных"
        }
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T?) {
        encode = { encoder in
            var container = encoder.singleValueContainer()
            if let value = value {
                try container.encode(value)
            } else {
                try container.encodeNil()
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
