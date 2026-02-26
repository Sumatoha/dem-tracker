import Foundation
import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case kazakh = "kk"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .kazakh: return "Қазақша"
        }
    }

    var flag: String {
        switch self {
        case .russian: return "🇷🇺"
        case .english: return "🇬🇧"
        case .kazakh: return "🇰🇿"
        }
    }
}

// MARK: - Language Manager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            loadStrings()
            objectWillChange.send()
        }
    }

    private var strings: [String: String] = [:]
    private let lock = NSLock()

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: saved) {
            self.currentLanguage = language
        } else {
            // Default to Russian
            self.currentLanguage = .russian
        }
        loadStrings()
    }

    private func loadStrings() {
        lock.lock()
        defer { lock.unlock() }

        // Try to load from lproj folder
        if let bundlePath = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath),
           let stringsPath = bundle.path(forResource: "Localizable", ofType: "strings"),
           let dict = NSDictionary(contentsOfFile: stringsPath) as? [String: String] {
            self.strings = dict
        } else {
            self.strings = [:]
        }
    }

    func localized(_ key: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        return strings[key] ?? key
    }

    func localized(_ key: String, _ args: CVarArg...) -> String {
        lock.lock()
        let format = strings[key] ?? key
        lock.unlock()
        return String(format: format, arguments: args)
    }
}

// MARK: - String Extension for Localization

extension String {
    var localized: String {
        LanguageManager.shared.localized(self)
    }

    func localized(_ args: CVarArg...) -> String {
        let format = LanguageManager.shared.localized(self)
        return String(format: format, arguments: args)
    }
}

// MARK: - Localization Keys

enum L {
    // MARK: - Common
    enum Common {
        static var done: String { "common.done".localized }
        static var cancel: String { "common.cancel".localized }
        static var save: String { "common.save".localized }
        static var error: String { "common.error".localized }
        static var ok: String { "common.ok".localized }
        static var loading: String { "common.loading".localized }
        static var or: String { "common.or".localized }
    }

    // MARK: - Tab Bar
    enum Tab {
        static var home: String { "tab.home".localized }
        static var history: String { "tab.history".localized }
        static var stats: String { "tab.stats".localized }
        static var profile: String { "tab.profile".localized }
    }

    // MARK: - Home
    enum Home {
        static var today: String { "home.today".localized }
        static var sinceLastOne: String { "home.since_last_one".localized }
        static var activity: String { "home.activity".localized }
        static var average: String { "home.average".localized }
        static var savings: String { "home.savings".localized }
        static var health: String { "home.health".localized }
        static var logButton: String { "home.log_button".localized }
    }

    // MARK: - Triggers
    enum Trigger {
        static var stress: String { "trigger.stress".localized }
        static var coffee: String { "trigger.coffee".localized }
        static var afterMeal: String { "trigger.after_meal".localized }
        static var alcohol: String { "trigger.alcohol".localized }
        static var boredom: String { "trigger.boredom".localized }
        static var social: String { "trigger.social".localized }
        static var beforeSleep: String { "trigger.before_sleep".localized }
        static var afterSleep: String { "trigger.after_sleep".localized }
        static var selectTrigger: String { "trigger.select".localized }
        static var whyNow: String { "trigger.why_now".localized }
        static var confirmChoice: String { "trigger.confirm_choice".localized }
        static var skip: String { "trigger.skip".localized }
        static var noTrigger: String { "trigger.no_trigger".localized }
    }

    // MARK: - History
    enum History {
        static var title: String { "history.title".localized }
        static var thisWeek: String { "history.this_week".localized }
        static var noData: String { "history.no_data".localized }
        static var cleanDays: String { "history.clean_days".localized }
        static var interval: String { "history.interval".localized }
        static var totalForMonth: String { "history.total_for_month".localized }
        static var trigger: String { "history.trigger".localized }
        static var today: String { "history.today".localized }
        static var yesterday: String { "history.yesterday".localized }
        static var noDataHint: String { "history.no_data_hint".localized }
        static var last30Days: String { "history.last_30_days".localized }
    }

    // MARK: - Stats
    enum Stats {
        static var title: String { "stats.title".localized }
        static var hourlyActivity: String { "stats.hourly_activity".localized }
        static func peakHours(_ time: String) -> String { "stats.peak_hours".localized(time) }
        static var mostFrequentTrigger: String { "stats.most_frequent_trigger".localized }
        static var longestStreak: String { "stats.longest_streak".localized }
        static var hours: String { "stats.hours".localized }
        static var withoutBreaks: String { "stats.without_breaks".localized }
        static var monthlyForecast: String { "stats.monthly_forecast".localized }
        static var program: String { "stats.program".localized }
        static var week: String { "stats.week".localized }
        static var limit: String { "stats.limit".localized }
        static var perDay: String { "stats.per_day".localized }
        static var daysInPlan: String { "stats.days_in_plan".localized }
        static var thisWeekLabel: String { "stats.this_week_label".localized }
        static var forecast: String { "stats.forecast".localized }
        static var noData: String { "stats.no_data".localized }
        static var motivationalText: String { "stats.motivational_text".localized }
        static var ifMaintainDynamics: String { "stats.if_maintain_dynamics".localized }
        static var startMarker: String { "stats.start_marker".localized }
        static var goalMarker: String { "stats.goal_marker".localized }
        static func weekOfTotal(_ current: Int, _ total: Int) -> String { "stats.week_of_total".localized(current, total) }
        static func limitPerDay(_ limit: Int) -> String { "stats.limit_per_day".localized(limit) }
        static func peakAt(_ startHour: Int, _ endHour: Int) -> String {
            String(format: "stats.peak_at".localized, startHour, endHour)
        }
        static var aheadBy: String { "stats.ahead_by".localized }
        static var behindBy: String { "stats.behind_by".localized }
        static var reachGoalBy: String { "stats.reach_goal_by".localized }
        static var keepGoing: String { "stats.keep_going".localized }
        static func weeksAhead(_ weeks: Int) -> String { "stats.weeks_ahead".localized(weeks) }
        static func weeksBehind(_ weeks: Int) -> String { "stats.weeks_behind".localized(weeks) }
        static var share: String { "stats.share".localized }
    }

    // MARK: - Profile
    enum Profile {
        static var title: String { "profile.title".localized }
        static var user: String { "profile.user".localized }
        static var editProfile: String { "profile.edit".localized }
        static var productType: String { "profile.product_type".localized }
        static var cigarettes: String { "profile.cigarettes".localized }
        static var iqos: String { "profile.iqos".localized }
        static var vape: String { "profile.vape".localized }
        static var mix: String { "profile.mix".localized }
        static var perDay: String { "profile.per_day".localized }
        static var perDayUsually: String { "profile.per_day_usually".localized }
        static var packPrice: String { "profile.pack_price".localized }
        static var sticksInPack: String { "profile.sticks_in_pack".localized }
        static var notifications: String { "profile.notifications".localized }
        static var eveningReportTime: String { "profile.evening_report_time".localized }
        static var programSettings: String { "profile.program_settings".localized }
        static var setupProgram: String { "profile.setup_program".localized }
        static var currentLimit: String { "profile.current_limit".localized }
        static func todayLimit(_ limit: Int) -> String { "profile.today_limit".localized(limit) }
        static var notConfigured: String { "profile.not_configured".localized }
        static var notSpecified: String { "profile.not_specified".localized }
        static var about: String { "profile.about".localized }
        static var privacyPolicy: String { "profile.privacy_policy".localized }
        static var termsOfService: String { "profile.terms_of_service".localized }
        static var support: String { "profile.support".localized }
        static var writeToTelegram: String { "profile.write_to_telegram".localized }
        static var version: String { "profile.version".localized }
        static var signOut: String { "profile.sign_out".localized }
        static var language: String { "profile.language".localized }
        static var selectGoal: String { "profile.select_goal".localized }
        static var programSetup: String { "profile.program_setup".localized }
        static var targetPerDay: String { "profile.target_per_day".localized }
        static var programDuration: String { "profile.program_duration".localized }
        static var quitDesc: String { "profile.quit_desc".localized }
        static var reduceDesc: String { "profile.reduce_desc".localized }
        static var observeDesc: String { "profile.observe_desc".localized }
        static func monthsFormat(_ months: Int) -> String { "profile.months_format".localized(months) }
        static var subscription: String { "profile.subscription".localized }
        static var subscriptionActive: String { "profile.subscription_active".localized }
        static var subscriptionSubscribe: String { "profile.subscription_subscribe".localized }
        static var manageSubscription: String { "profile.manage_subscription".localized }
        static var trialExpired: String { "profile.trial_expired".localized }
        static var discardChanges: String { "profile.discard_changes".localized }
        static var discard: String { "profile.discard".localized }
        static var discardChangesMessage: String { "profile.discard_changes_message".localized }
        static var supportEmail: String { "profile.support_email".localized }
        static var supportDescription: String { "profile.support_description".localized }
        static var deleteAccount: String { "profile.delete_account".localized }
        static var deleteAccountTitle: String { "profile.delete_account_title".localized }
        static var deleteAccountMessage: String { "profile.delete_account_message".localized }
        static var delete: String { "profile.delete".localized }
    }

    // MARK: - Onboarding
    enum Onboarding {
        static var welcome: String { "onboarding.welcome".localized }
        static var hello: String { "onboarding.hello".localized }
        static var whatsYourName: String { "onboarding.whats_your_name".localized }
        static var nameDescription: String { "onboarding.name_description".localized }
        static var namePlaceholder: String { "onboarding.name_placeholder".localized }
        static var enterName: String { "onboarding.enter_name".localized }
        static var continueButton: String { "onboarding.continue".localized }
        static var next: String { "onboarding.next".localized }
        static var back: String { "onboarding.back".localized }
        static var myChoice: String { "onboarding.my_choice".localized }
        static var productTypeDescription: String { "onboarding.product_type_description".localized }
        static var typeLabel: String { "onboarding.type_label".localized }
        static var canChangeLater: String { "onboarding.can_change_later".localized }
        static var currentLevel: String { "onboarding.current_level".localized }
        static var baselineDescription: String { "onboarding.baseline_description".localized }
        static var howManyPerDay: String { "onboarding.how_many_per_day".localized }
        static var inPack: String { "onboarding.in_pack".localized }
        static var whatDoYouSmoke: String { "onboarding.what_do_you_smoke".localized }
        static var howMuchPerDay: String { "onboarding.how_much_per_day".localized }
        static var piecesPerDay: String { "onboarding.pieces_per_day".localized }
        static var packPriceLabel: String { "onboarding.pack_price_label".localized }
        static var sticksInPackLabel: String { "onboarding.sticks_in_pack_label".localized }
        static var whatIsYourGoal: String { "onboarding.what_is_your_goal".localized }
        static var goalDescription: String { "onboarding.goal_description".localized }
        static var goalQuit: String { "onboarding.goal_quit".localized }
        static var goalReduce: String { "onboarding.goal_reduce".localized }
        static var goalObserve: String { "onboarding.goal_observe".localized }
        static var goalQuitDesc: String { "onboarding.goal_quit_desc".localized }
        static var goalReduceDesc: String { "onboarding.goal_reduce_desc".localized }
        static var goalObserveDesc: String { "onboarding.goal_observe_desc".localized }
        static var targetAmount: String { "onboarding.target_amount".localized }
        static var duration: String { "onboarding.duration".localized }
        static var durationDescription: String { "onboarding.duration_description".localized }
        static var months: String { "onboarding.months".localized }
        static var start: String { "onboarding.start".localized }
        static var yourPlan: String { "onboarding.your_plan".localized }
        static var planDescription: String { "onboarding.plan_description".localized }
        static var selectGoal: String { "onboarding.select_goal".localized }
        static var justObserving: String { "onboarding.just_observing".localized }
        static var setComfortLevel: String { "onboarding.set_comfort_level".localized }
        static var duration1Month: String { "onboarding.duration_1_month".localized }
        static var duration3Months: String { "onboarding.duration_3_months".localized }
        static var duration6Months: String { "onboarding.duration_6_months".localized }
        static var durationCustom: String { "onboarding.duration_custom".localized }
        static var intensive: String { "onboarding.intensive".localized }
        static var optimal: String { "onboarding.optimal".localized }
        static var gentle: String { "onboarding.gentle".localized }
        static var chooseDuration: String { "onboarding.choose_duration".localized }
        static func stepOf(_ step: Int, _ total: Int) -> String { "onboarding.step_of".localized(step, total) }
        static func recommendationText(_ baseline: Int, _ recommendation: String) -> String {
            "onboarding.recommendation".localized(baseline, recommendation)
        }
        static var saveError: String { "onboarding.save_error".localized }
    }

    // MARK: - Health
    enum Health {
        static var title: String { "health.title".localized }
        static func whatDoesItMean(_ percent: Int) -> String { "health.what_does_it_mean".localized(percent) }
        static var explanation: String { "health.explanation".localized }
        static var lastCigarette: String { "health.last_cigarette".localized }
        static var recovery: String { "health.recovery".localized }
        static var howItWorks: String { "health.how_it_works".localized }
        static var afterCigarette: String { "health.after_cigarette".localized }
        static var longerWithout: String { "health.longer_without".localized }
        static var threeDays: String { "health.three_days".localized }
        static var recoveryStages: String { "health.recovery_stages".localized }
        static var minutes20: String { "health.minutes_20".localized }
        static var hours2: String { "health.hours_2".localized }
        static var hours8: String { "health.hours_8".localized }
        static var hours24: String { "health.hours_24".localized }
        static var hours48: String { "health.hours_48".localized }
        static var hours72: String { "health.hours_72".localized }
        static var benefit20min: String { "health.benefit_20min".localized }
        static var benefit2h: String { "health.benefit_2h".localized }
        static var benefit8h: String { "health.benefit_8h".localized }
        static var benefit24h: String { "health.benefit_24h".localized }
        static var benefit48h: String { "health.benefit_48h".localized }
        static var benefit72h: String { "health.benefit_72h".localized }
    }

    // MARK: - Savings
    enum Savings {
        static var title: String { "savings.title".localized }
        static var savedToday: String { "savings.saved_today".localized }
        static var howCalculated: String { "savings.how_calculated".localized }
        static var usuallySmoke: String { "savings.usually_smoke".localized }
        static var todaySmoked: String { "savings.today_smoked".localized }
        static var saved: String { "savings.saved".localized }
        static var pricePerUnit: String { "savings.price_per_unit".localized }
        static var total: String { "savings.total".localized }
        static var hint: String { "savings.hint".localized }
    }

    // MARK: - Forecast
    enum Forecast {
        static var title: String { "forecast.title".localized }
        static var explanation: String { "forecast.explanation".localized }
        static var currentAverage: String { "forecast.current_average".localized }
        static var savePerDay: String { "forecast.save_per_day".localized }
        static var perMonth: String { "forecast.per_month".localized }
        static var hint: String { "forecast.hint".localized }
    }

    // MARK: - Program
    enum Program {
        static var title: String { "program.title".localized }
        static var whatIsProgram: String { "program.what_is_program".localized }
        static var programExplanation: String { "program.explanation".localized }
        static var howItWorks: String { "program.how_it_works".localized }
        static var startingPoint: String { "program.starting_point".localized }
        static var goal: String { "program.goal".localized }
        static var timeline: String { "program.timeline".localized }
        static var current: String { "program.current".localized }
        static var whatIsForecast: String { "program.what_is_forecast".localized }
        static var forecastExplanation: String { "program.forecast_explanation".localized }
        static var whatIsDaysInPlan: String { "program.what_is_days_in_plan".localized }
        static var daysInPlanExplanation: String { "program.days_in_plan_explanation".localized }
        static var quit: String { "program.quit".localized }
        static var reduce: String { "program.reduce".localized }
        static var observe: String { "program.observe".localized }
        static var fullQuit: String { "program.full_quit".localized }
        static var reduceTo: String { "program.reduce_to".localized }
        static var startedWith: String { "program.started_with".localized }
        static var weeksFormat: String { "program.weeks_format".localized }
        static var weekLimit: String { "program.week_limit".localized }
    }

    // MARK: - Auth
    enum Auth {
        static var signInWithApple: String { "auth.sign_in_with_apple".localized }
        static var welcomeTitle: String { "auth.welcome_title".localized }
        static var welcomeSubtitle: String { "auth.welcome_subtitle".localized }
        static var termsAgreement: String { "auth.terms_agreement".localized }
    }

    // MARK: - Notifications
    enum Notifications {
        // Evening summary
        static var eveningTitle: String { "notifications.evening_title".localized }
        static var eveningZero: String { "notifications.evening_zero".localized }
        static func eveningUnderLimit(_ count: Int, _ limit: Int) -> String { "notifications.evening_under_limit".localized(count, limit) }
        static func eveningAtLimit(_ count: Int, _ limit: Int) -> String { "notifications.evening_at_limit".localized(count, limit) }
        static func eveningOverLimit(_ count: Int, _ limit: Int) -> String { "notifications.evening_over_limit".localized(count, limit) }
        static func eveningNoLimit(_ count: Int) -> String { "notifications.evening_no_limit".localized(count) }

        // Limit exceeded
        static var limitExceededTitle: String { "notifications.limit_exceeded_title".localized }
        static func limitExceededBody(_ limit: Int) -> String { "notifications.limit_exceeded_body".localized(limit) }

        // Health milestones
        static var milestone2h: String { "notifications.milestone_2h".localized }
        static var milestone2hBody: String { "notifications.milestone_2h_body".localized }
        static var milestone6h: String { "notifications.milestone_6h".localized }
        static var milestone6hBody: String { "notifications.milestone_6h_body".localized }
        static var milestone12h: String { "notifications.milestone_12h".localized }
        static var milestone12hBody: String { "notifications.milestone_12h_body".localized }
        static var milestone24h: String { "notifications.milestone_24h".localized }
        static var milestone24hBody: String { "notifications.milestone_24h_body".localized }
        static var milestone72h: String { "notifications.milestone_72h".localized }
        static var milestone72hBody: String { "notifications.milestone_72h_body".localized }
    }

    // MARK: - Time
    enum Time {
        static func minutesAgo(_ minutes: Int) -> String { "time.minutes_ago".localized(minutes) }
        static func hoursAgo(_ hours: Int) -> String { "time.hours_ago".localized(hours) }
        static func daysAgo(_ days: Int) -> String { "time.days_ago".localized(days) }
        static var longAgo: String { "time.long_ago".localized }
    }

    // MARK: - Units
    enum Units {
        static var pieces: String { "units.pieces".localized }
        static var piecesPerDay: String { "units.pieces_per_day".localized }
        static var tenge: String { "units.tenge".localized }
    }

    // MARK: - Quotes
    enum Quotes {
        static var quote1: String { "quotes.quote1".localized }
        static var quote2: String { "quotes.quote2".localized }
        static var quote3: String { "quotes.quote3".localized }
        static var quote4: String { "quotes.quote4".localized }
        static var quote5: String { "quotes.quote5".localized }

        static var all: [String] {
            [quote1, quote2, quote3, quote4, quote5]
        }
    }

    // MARK: - Health Status
    enum HealthStatus {
        static var veryRecentTitle: String { "health_status.very_recent_title".localized }
        static var recentTitle: String { "health_status.recent_title".localized }
        static var recoveringTitle: String { "health_status.recovering_title".localized }
        static var improvingTitle: String { "health_status.improving_title".localized }
        static var strongTitle: String { "health_status.strong_title".localized }
        static var excellentTitle: String { "health_status.excellent_title".localized }
        static var veryRecentDesc: String { "health_status.very_recent_desc".localized }
        static var recentDesc: String { "health_status.recent_desc".localized }
        static var recoveringDesc: String { "health_status.recovering_desc".localized }
        static var improvingDesc: String { "health_status.improving_desc".localized }
        static var strongDesc: String { "health_status.strong_desc".localized }
        static var excellentDesc: String { "health_status.excellent_desc".localized }
    }

    // MARK: - Paywall
    enum Paywall {
        static var days: String { "paywall.days".localized }
        static var dontLoseProgress: String { "paywall.dont_lose_progress".localized }
        static var subtitle: String { "paywall.subtitle".localized }
        static var featureStats: String { "paywall.feature_stats".localized }
        static var featureNotifications: String { "paywall.feature_notifications".localized }
        static var featureGoals: String { "paywall.feature_goals".localized }
        static var featureHealth: String { "paywall.feature_health".localized }
        static var plan1Month: String { "paywall.plan_1_month".localized }
        static var plan6Months: String { "paywall.plan_6_months".localized }
        static var plan6MonthsSubtitle: String { "paywall.plan_6_months_subtitle".localized }
        static var plan1Year: String { "paywall.plan_1_year".localized }
        static var bestChoice: String { "paywall.best_choice".localized }
        static var month: String { "paywall.month".localized }
        static var startTrial: String { "paywall.start_trial".localized }
        static func priceDisclaimer(_ price: String) -> String { "paywall.price_disclaimer".localized(price) }
        static var restore: String { "paywall.restore".localized }
        static var terms: String { "paywall.terms".localized }
        static var privacy: String { "paywall.privacy".localized }
        static var error: String { "paywall.error".localized }
        static var subscriptionActive: String { "paywall.subscription_active".localized }
        static func trialDaysLeft(_ days: Int) -> String { "paywall.trial_days_left".localized(days) }
        static var cigarettesReduced: String { "paywall.cigarettes_reduced".localized }
        static var moneySaved: String { "paywall.money_saved".localized }
        static var noPurchasesToRestore: String { "paywall.no_purchases_to_restore".localized }
        static var subscribe: String { "paywall.subscribe".localized }
        static var subscribeNow: String { "paywall.subscribe_now".localized }
        static var productsNotLoaded: String { "paywall.products_not_loaded".localized }
        static var unlockPremium: String { "paywall.unlock_premium".localized }
        static var premiumSubtitle: String { "paywall.premium_subtitle".localized }
        static var startTrialTitle: String { "paywall.start_trial_title".localized }
        static var trialFree: String { "paywall.trial_free".localized }
        static var trialDisclaimer: String { "paywall.trial_disclaimer".localized }
        static var popular: String { "paywall.popular".localized }
    }

    // MARK: - Paywall Onboarding
    enum PaywallOnboarding {
        static var page1Title: String { "paywall_onboarding.page1_title".localized }
        static var page1Subtitle: String { "paywall_onboarding.page1_subtitle".localized }
        static var page2Title: String { "paywall_onboarding.page2_title".localized }
        static var page2Subtitle: String { "paywall_onboarding.page2_subtitle".localized }
        static var page3Title: String { "paywall_onboarding.page3_title".localized }
        static var page3Subtitle: String { "paywall_onboarding.page3_subtitle".localized }
        static var page4Title: String { "paywall_onboarding.page4_title".localized }
        static var page4Subtitle: String { "paywall_onboarding.page4_subtitle".localized }
        static var next: String { "paywall_onboarding.next".localized }
        static var continueButton: String { "paywall_onboarding.continue".localized }
        static var skip: String { "paywall_onboarding.skip".localized }
    }
}
