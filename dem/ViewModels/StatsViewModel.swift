import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var logs: [SmokingLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let supabase = SupabaseManager.shared
    private let cache = CacheManager.shared

    init() {
        // Load cache synchronously on init - no flash
        if let cachedLogs = cache.getCachedWeeklyLogs() {
            logs = cachedLogs
        }
    }

    var profile: Profile? {
        supabase.currentProfile
    }

    var hourlyDistribution: [(hour: Int, count: Int)] {
        let calendar = Calendar.current
        var distribution = Array(repeating: 0, count: 24)

        for log in logs {
            let hour = calendar.component(.hour, from: log.createdAt)
            distribution[hour] += 1
        }

        return distribution.enumerated().map { (hour: $0.offset, count: $0.element) }
    }

    var peakHours: String {
        let sorted = hourlyDistribution.sorted { $0.count > $1.count }
        guard let peak = sorted.first, peak.count > 0 else {
            return "Нет данных"
        }

        let startHour = peak.hour
        let endHour = (peak.hour + 1) % 24

        return String(format: "Пик в %02d:00 — %02d:00", startHour, endHour)
    }

    var mostFrequentTrigger: (trigger: TriggerType, percentage: Int)? {
        let triggeredLogs = logs.compactMap { $0.trigger }
        guard !triggeredLogs.isEmpty else { return nil }

        let counts = Dictionary(grouping: triggeredLogs) { $0 }
            .mapValues { $0.count }

        guard let maxTrigger = counts.max(by: { $0.value < $1.value }) else {
            return nil
        }

        let percentage = Int(Double(maxTrigger.value) / Double(triggeredLogs.count) * 100)
        return (maxTrigger.key, percentage)
    }

    var longestStreak: Int {
        guard !logs.isEmpty else { return 0 }

        let sortedLogs = logs.sorted { $0.createdAt < $1.createdAt }

        var maxInterval: TimeInterval = 0

        for i in 0..<(sortedLogs.count - 1) {
            let interval = sortedLogs[i + 1].createdAt.timeIntervalSince(sortedLogs[i].createdAt)
            maxInterval = max(maxInterval, interval)
        }

        // Also check time since last log
        if let lastLog = sortedLogs.last {
            let sinceLast = Date().timeIntervalSince(lastLog.createdAt)
            maxInterval = max(maxInterval, sinceLast)
        }

        return Int(maxInterval / 3600) // Convert to hours
    }

    var monthlyForecastSavings: Int {
        guard let profile = profile else { return 0 }

        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        let daysPassed = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 1
        guard daysPassed > 0 else { return 0 }

        let logsThisMonth = logs.filter { $0.createdAt >= startOfMonth }
        let averagePerDay = Double(logsThisMonth.count) / Double(daysPassed)

        let savedPerDay = Double(profile.safeBaselinePerDay) - averagePerDay
        guard savedPerDay > 0 else { return 0 }

        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        return Int(savedPerDay * profile.pricePerUnit * Double(daysInMonth))
    }

    // MARK: - Program Analytics

    var hasProgramActive: Bool {
        profile?.hasProgramActive ?? false
    }

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

    /// Данные для графика программы: план vs факт по неделям
    var programChartData: [(week: Int, planned: Int, actual: Double)] {
        guard let profile = profile,
              profile.hasProgramActive,
              let startValue = profile.programStartValue,
              let targetValue = profile.programTargetValue,
              let durationMonths = profile.programDurationMonths,
              let startDate = profile.programStartDate else {
            return []
        }

        let totalWeeks = ProgramCalculator.totalWeeks(durationMonths: durationMonths)
        let currentWeek = ProgramCalculator.currentWeekNumber(startDate: startDate)
        let calendar = Calendar.current

        var data: [(Int, Int, Double)] = []

        for week in 1...min(currentWeek, totalWeeks) {
            let plannedLimit = ProgramCalculator.limitForWeek(
                weekNumber: week,
                startValue: startValue,
                targetValue: targetValue,
                totalWeeks: totalWeeks
            )

            // Calculate actual average for this week
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startDate) ?? startDate
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: week, to: startDate) ?? Date()

            let weekLogs = logs.filter { $0.createdAt >= weekStart && $0.createdAt < weekEnd }

            // Group by day to get daily counts
            let grouped = Dictionary(grouping: weekLogs) { log in
                calendar.startOfDay(for: log.createdAt)
            }

            let daysWithData = max(1, grouped.count)
            let actualAverage = Double(weekLogs.count) / Double(daysWithData)

            data.append((week, plannedLimit, actualAverage))
        }

        return data
    }

    /// Количество дней в плане за текущую неделю
    var daysInPlanThisWeek: (inPlan: Int, total: Int) {
        guard let profile = profile,
              profile.hasProgramActive,
              let startValue = profile.programStartValue,
              let targetValue = profile.programTargetValue,
              let durationMonths = profile.programDurationMonths,
              let startDate = profile.programStartDate else {
            return (0, 0)
        }

        let currentLimit = ProgramCalculator.currentDailyLimit(
            startValue: startValue,
            targetValue: targetValue,
            durationMonths: durationMonths,
            startDate: startDate
        )

        let startOfWeek = ProgramCalculator.startOfCurrentWeek()
        return ProgramCalculator.daysInPlanThisWeek(logs: logs, limit: currentLimit, startOfWeek: startOfWeek)
    }

    /// Прогноз завершения программы
    var projectionText: String {
        guard let profile = profile,
              profile.hasProgramActive,
              let startValue = profile.programStartValue,
              let targetValue = profile.programTargetValue,
              let durationMonths = profile.programDurationMonths,
              let startDate = profile.programStartDate else {
            return ""
        }

        let totalWeeks = ProgramCalculator.totalWeeks(durationMonths: durationMonths)
        let calendar = Calendar.current
        let plannedEndDate = calendar.date(byAdding: .weekOfYear, value: totalWeeks, to: startDate) ?? Date()

        // Calculate current average
        let daysSinceStart = max(1, calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 1)
        let logsCount = logs.filter { $0.createdAt >= startDate }.count
        let currentAverage = Double(logsCount) / Double(daysSinceStart)

        if let projectedDate = ProgramCalculator.projectedCompletionDate(
            currentAverage: currentAverage,
            targetValue: targetValue,
            startDate: startDate,
            startValue: startValue
        ) {
            let weeksAhead = calendar.dateComponents([.weekOfYear], from: projectedDate, to: plannedEndDate).weekOfYear ?? 0

            if weeksAhead > 0 {
                return "С опережением на \(weeksAhead) нед."
            } else if weeksAhead < 0 {
                return "Отставание — \(abs(weeksAhead)) нед."
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ru_RU")
                formatter.dateFormat = "d MMMM"
                return "Достигнете цели к \(formatter.string(from: projectedDate))"
            }
        }

        return "Продолжайте в том же духе"
    }

    var currentWeekNumber: Int {
        guard let startDate = profile?.programStartDate else { return 1 }
        return ProgramCalculator.currentWeekNumber(startDate: startDate)
    }

    var totalWeeksInProgram: Int {
        guard let durationMonths = profile?.programDurationMonths else { return 1 }
        return ProgramCalculator.totalWeeks(durationMonths: durationMonths)
    }

    func loadData() async {
        // Fetch fresh data from server
        do {
            let calendar = Calendar.current
            let today = Date()

            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) else {
                return
            }

            let freshLogs = try await supabase.fetchLogsForDateRange(from: monthAgo, to: today)
            logs = freshLogs

            // Update cache
            cache.cacheWeeklyLogs(freshLogs)
        } catch {
            if logs.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
