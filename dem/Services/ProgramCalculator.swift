import Foundation

struct ProgramCalculator {

    /// Текущий дневной лимит на основе программы
    /// Снижение начинается с первой недели
    static func currentDailyLimit(
        startValue: Int,
        targetValue: Int,
        durationMonths: Int,
        startDate: Date
    ) -> Int {
        let totalWeeks = max(1, durationMonths * 4)
        let weekNumber = currentWeekNumber(startDate: startDate)

        // Снижение начинается с 1-й недели
        // Неделя 1: небольшое снижение, Неделя N: достигаем targetValue
        let reduction = Double(startValue - targetValue) * Double(weekNumber) / Double(totalWeeks)

        return max(targetValue, startValue - Int(reduction.rounded()))
    }

    /// Номер текущей недели (1-based)
    static func currentWeekNumber(startDate: Date) -> Int {
        let weeks = Calendar.current.dateComponents(
            [.weekOfYear], from: startDate, to: Date()
        ).weekOfYear ?? 0
        return max(1, weeks + 1)
    }

    /// Общее количество недель в программе
    static func totalWeeks(durationMonths: Int) -> Int {
        return max(1, durationMonths * 4)
    }

    /// Процент дней за текущую неделю когда уложился в лимит
    static func weekComplianceRate(logs: [SmokingLog], limit: Int, startOfWeek: Date) -> Double {
        let calendar = Calendar.current
        var daysInLimit = 0
        var totalDays = 0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek),
                  day <= Date() else { continue }

            totalDays += 1
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayCount = logs.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }.count

            if dayCount <= limit { daysInLimit += 1 }
        }

        guard totalDays > 0 else { return 0 }
        return Double(daysInLimit) / Double(totalDays)
    }

    /// Количество дней в плане за текущую неделю
    static func daysInPlanThisWeek(logs: [SmokingLog], limit: Int, startOfWeek: Date) -> (inPlan: Int, total: Int) {
        let calendar = Calendar.current
        var daysInLimit = 0
        var totalDays = 0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek),
                  day <= Date() else { continue }

            totalDays += 1
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayCount = logs.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }.count

            if dayCount <= limit { daysInLimit += 1 }
        }

        return (daysInLimit, totalDays)
    }

    /// Прогноз даты достижения цели на основе текущего тренда
    static func projectedCompletionDate(
        currentAverage: Double,
        targetValue: Int,
        startDate: Date,
        startValue: Int
    ) -> Date? {
        guard currentAverage > Double(targetValue) else { return Date() }
        let daysElapsed = max(1, Calendar.current.dateComponents(
            [.day], from: startDate, to: Date()
        ).day ?? 1)
        let dailyReduction = (Double(startValue) - currentAverage) / Double(daysElapsed)
        guard dailyReduction > 0 else { return nil }
        let remainingReduction = currentAverage - Double(targetValue)
        let daysNeeded = Int(remainingReduction / dailyReduction)
        return Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date())
    }

    /// Вычислить плановый лимит для конкретной недели
    static func limitForWeek(
        weekNumber: Int,
        startValue: Int,
        targetValue: Int,
        totalWeeks: Int
    ) -> Int {
        let clampedWeek = min(weekNumber, totalWeeks)
        let reduction = Double(startValue - targetValue) * Double(clampedWeek) / Double(totalWeeks)
        return max(targetValue, startValue - Int(reduction.rounded()))
    }

    /// Начало текущей недели
    static func startOfCurrentWeek() -> Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    /// Среднее количество за период
    static func averagePerDay(logs: [SmokingLog], days: Int) -> Double {
        guard days > 0 else { return 0 }
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date()))!

        let filteredLogs = logs.filter { $0.createdAt >= startDate }
        return Double(filteredLogs.count) / Double(days)
    }
}
