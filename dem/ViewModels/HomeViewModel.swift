import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayLogs: [SmokingLog] = []
    @Published var weeklyLogs: [SmokingLog] = []
    @Published var isLoading = false
    @Published var showTriggerSelection = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let supabase = SupabaseManager.shared
    private let cache = CacheManager.shared

    init() {
        // Load cache synchronously on init - no flash
        if let cachedToday = cache.getCachedTodayLogs() {
            todayLogs = cachedToday
        }
        if let cachedWeekly = cache.getCachedWeeklyLogs() {
            weeklyLogs = cachedWeekly
        }
    }

    var todayCount: Int {
        todayLogs.count
    }

    var lastLogDate: Date? {
        // Берём последний лог из всех доступных (не только сегодня)
        // weeklyLogs содержит логи за 7 дней, отсортированные по дате (новые первые)
        let allLogs = (todayLogs + weeklyLogs)
            .sorted { $0.createdAt > $1.createdAt }
        return allLogs.first?.createdAt
    }

    var profile: Profile? {
        supabase.currentProfile
    }

    var averagePerDay: Double {
        guard !weeklyLogs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weeklyLogs) { log in
            calendar.startOfDay(for: log.createdAt)
        }

        let totalDays = max(grouped.keys.count, 1)
        return Double(weeklyLogs.count) / Double(totalDays)
    }

    var todaySavings: Int {
        guard let profile = profile else { return 0 }
        let saved = profile.safeBaselinePerDay - todayCount
        guard saved > 0 else { return 0 }
        return Int(Double(saved) * profile.pricePerUnit)
    }

    var hoursSinceLastLog: Double {
        guard let lastLog = lastLogDate else { return 999 }
        return Date().timeIntervalSince(lastLog) / 3600
    }

    var healthStatus: HealthStatus {
        let hours = hoursSinceLastLog

        switch hours {
        case 0..<1: return .veryRecent
        case 1..<2: return .recent
        case 2..<8: return .recovering
        case 8..<24: return .improving
        case 24..<72: return .strong
        default: return .excellent
        }
    }

    var healthStatusText: String {
        "+\(healthPercentage)%"
    }

    var healthStatusIcon: String {
        "arrow.up.right"
    }

    var healthPercentage: Int {
        guard let lastLog = lastLogDate else { return 100 }
        let hoursSince = Date().timeIntervalSince(lastLog) / 3600

        switch hoursSince {
        case 0..<1: return 5
        case 1..<2: return 15
        case 2..<4: return 25
        case 4..<8: return 40
        case 8..<12: return 55
        case 12..<24: return 70
        case 24..<48: return 85
        default: return 95
        }
    }

    var dailyCounts: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        dayFormatter.dateFormat = "EE"

        var result: [(String, Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            let dayName = dayFormatter.string(from: date).uppercased()
            let count = weeklyLogs.filter { log in
                calendar.isDate(log.createdAt, inSameDayAs: date)
            }.count

            result.append((dayName, count))
        }

        return result
    }

    var motivationalQuote: String {
        let quotes = L.Quotes.all
        let index = Calendar.current.component(.day, from: Date()) % quotes.count
        return quotes[index]
    }

    // MARK: - Program Properties

    /// Активна ли программа (quit или reduce)
    var hasProgramActive: Bool {
        profile?.hasProgramActive ?? false
    }

    /// Текущий дневной лимит на основе программы
    var currentDailyLimit: Int? {
        guard let profile = profile,
              profile.hasProgramActive,
              let startValue = profile.programStartValue,
              let targetValue = profile.programTargetValue,
              let durationMonths = profile.programDurationMonths,
              let startDate = profile.programStartDate else {
            return nil
        }

        return ProgramCalculator.currentDailyLimit(
            startValue: startValue,
            targetValue: targetValue,
            durationMonths: durationMonths,
            startDate: startDate
        )
    }

    /// Номер текущей недели
    var currentWeekNumber: Int {
        guard let startDate = profile?.programStartDate else { return 1 }
        return ProgramCalculator.currentWeekNumber(startDate: startDate)
    }

    /// Общее количество недель в программе
    var totalWeeksInProgram: Int {
        guard let durationMonths = profile?.programDurationMonths else { return 1 }
        return ProgramCalculator.totalWeeks(durationMonths: durationMonths)
    }

    /// Прогресс к дневному лимиту (0.0 - 1.0+)
    var dailyLimitProgress: Double {
        guard let limit = currentDailyLimit, limit > 0 else { return 0 }
        return Double(todayCount) / Double(limit)
    }

    /// Превышен ли лимит
    var isOverLimit: Bool {
        guard let limit = currentDailyLimit else { return false }
        return todayCount > limit
    }

    func loadData() async {
        // Fetch fresh data from server
        do {
            async let todayTask = supabase.fetchTodayLogs()
            async let weeklyTask = supabase.fetchWeeklyLogs()

            let (today, weekly) = try await (todayTask, weeklyTask)
            todayLogs = today
            weeklyLogs = weekly

            // Update cache
            cache.cacheTodayLogs(today)
            cache.cacheWeeklyLogs(weekly)
        } catch {
            if todayLogs.isEmpty && weeklyLogs.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func onLogButtonTapped() {
        Haptics.heavy()
        showTriggerSelection = true
    }

    func submitLog(trigger: TriggerType?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.createLog(trigger: trigger)

            // Immediately add to local state for instant UI update
            let newLog = SmokingLog(
                id: Int64.random(in: 1...999999),
                userId: supabase.currentUser?.id ?? UUID(),
                productType: profile?.productType ?? .cigarette,
                trigger: trigger,
                mood: nil,
                nicotineMg: profile?.nicotinePerUnit,
                price: profile != nil ? Int(profile!.pricePerUnit) : nil,
                note: nil,
                createdAt: Date()
            )

            todayLogs.insert(newLog, at: 0)
            weeklyLogs.insert(newLog, at: 0)

            // Update cache with new log
            cache.addLogToCache(newLog)

            Haptics.success()
            showTriggerSelection = false

            // Update notifications
            await updateNotifications()

            // Refresh in background to get correct IDs
            Task {
                await loadData()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
        }
    }

    // MARK: - Notifications

    /// Обновить уведомления после каждого лога
    func updateNotifications() async {
        guard profile?.safeNotificationsEnabled == true else { return }

        let timeComponents = NotificationManager.shared.parseTime(profile?.safeNotificationTime ?? "22:00")

        // Обновить вечернее уведомление и milestones
        NotificationManager.shared.scheduleNotifications(
            eveningHour: timeComponents.hour,
            eveningMinute: timeComponents.minute,
            todayCount: todayCount,
            dailyLimit: currentDailyLimit,
            lastLogDate: lastLogDate
        )

        // Проверяем превышение лимита (отправить уведомление через 1 минуту)
        if let limit = currentDailyLimit, todayCount == limit + 1 {
            // Только при первом превышении (лимит + 1)
            NotificationManager.shared.sendLimitExceededNotification(limit: limit)
        }
    }

    /// Начальная настройка уведомлений при запуске приложения
    func setupInitialNotifications() async {
        guard profile?.safeNotificationsEnabled == true else { return }

        let timeComponents = NotificationManager.shared.parseTime(profile?.safeNotificationTime ?? "22:00")

        // Вечернее уведомление и milestones
        NotificationManager.shared.scheduleNotifications(
            eveningHour: timeComponents.hour,
            eveningMinute: timeComponents.minute,
            todayCount: todayCount,
            dailyLimit: currentDailyLimit,
            lastLogDate: lastLogDate
        )
    }
}
