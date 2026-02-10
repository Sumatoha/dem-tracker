import Foundation

enum SupabaseConfig {
    static let url = URL(string: "https://edjfpvowoqvbelimyknr.supabase.co")!
    static let anonKey = "sb_publishable_vUHbhq8loMLRfCIdigO5lQ_sEztff05"
}

enum TableName {
    static let profiles = "profiles"
    static let logs = "logs"
    static let cravings = "cravings"
    static let achievements = "achievements"
    static let dailyStats = "daily_stats"
    static let triggerStats = "trigger_stats"
}

enum ColumnName {
    enum Profile {
        static let id = "id"
        static let name = "name"
        static let productType = "product_type"
        static let baselinePerDay = "baseline_per_day"
        static let packPrice = "pack_price"
        static let sticksInPack = "sticks_in_pack"
        static let goalType = "goal_type"
        static let goalPerDay = "goal_per_day"
        static let goalDate = "goal_date"
        static let onboardingDone = "onboarding_done"
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
        static let programType = "program_type"
        static let programStartValue = "program_start_value"
        static let programTargetValue = "program_target_value"
        static let programDurationMonths = "program_duration_months"
        static let programStartDate = "program_start_date"
        static let notificationTime = "notification_time"
        static let notificationsEnabled = "notifications_enabled"
    }

    enum Log {
        static let id = "id"
        static let userId = "user_id"
        static let productType = "product_type"
        static let trigger = "trigger"
        static let mood = "mood"
        static let nicotineMg = "nicotine_mg"
        static let price = "price"
        static let note = "note"
        static let createdAt = "created_at"
    }
}
