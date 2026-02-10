import Foundation

// Non-actor for sync access, thread-safe via serial queue
final class CacheManager: @unchecked Sendable {
    static let shared = CacheManager()

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.dem.cache")

    // Cache keys
    private enum Keys {
        static let todayLogs = "cache_today_logs"
        static let weeklyLogs = "cache_weekly_logs"
        static let allLogs = "cache_all_logs"
        static let todayLogsDate = "cache_today_logs_date"
        static let hourlyDistribution = "cache_hourly_distribution"
        static let triggerStats = "cache_trigger_stats"
    }

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Today Logs

    func cacheTodayLogs(_ logs: [SmokingLog]) {
        if let data = try? encoder.encode(logs) {
            userDefaults.set(data, forKey: Keys.todayLogs)
            userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.todayLogsDate)
        }
    }

    func getCachedTodayLogs() -> [SmokingLog]? {
        // Check if cache is from today
        let cachedTimestamp = userDefaults.double(forKey: Keys.todayLogsDate)
        let cachedDate = Date(timeIntervalSince1970: cachedTimestamp)

        guard Calendar.current.isDateInToday(cachedDate) else {
            return nil
        }

        guard let data = userDefaults.data(forKey: Keys.todayLogs),
              let logs = try? decoder.decode([SmokingLog].self, from: data) else {
            return nil
        }

        return logs
    }

    // MARK: - All Logs (for History)

    func cacheAllLogs(_ logs: [SmokingLog]) {
        if let data = try? encoder.encode(logs) {
            userDefaults.set(data, forKey: Keys.allLogs)
        }
    }

    func getCachedAllLogs() -> [SmokingLog]? {
        guard let data = userDefaults.data(forKey: Keys.allLogs),
              let logs = try? decoder.decode([SmokingLog].self, from: data) else {
            return nil
        }
        return logs
    }

    // MARK: - Weekly Logs (for Stats)

    func cacheWeeklyLogs(_ logs: [SmokingLog]) {
        if let data = try? encoder.encode(logs) {
            userDefaults.set(data, forKey: Keys.weeklyLogs)
        }
    }

    func getCachedWeeklyLogs() -> [SmokingLog]? {
        guard let data = userDefaults.data(forKey: Keys.weeklyLogs),
              let logs = try? decoder.decode([SmokingLog].self, from: data) else {
            return nil
        }
        return logs
    }

    // MARK: - Add new log to cache

    func addLogToCache(_ log: SmokingLog) {
        // Add to today logs
        var todayLogs = getCachedTodayLogs() ?? []
        todayLogs.insert(log, at: 0)
        cacheTodayLogs(todayLogs)

        // Add to all logs
        var allLogs = getCachedAllLogs() ?? []
        allLogs.insert(log, at: 0)
        cacheAllLogs(allLogs)

        // Add to weekly logs
        var weeklyLogs = getCachedWeeklyLogs() ?? []
        weeklyLogs.insert(log, at: 0)
        cacheWeeklyLogs(weeklyLogs)
    }

    // MARK: - Clear cache

    func clearCache() {
        userDefaults.removeObject(forKey: Keys.todayLogs)
        userDefaults.removeObject(forKey: Keys.todayLogsDate)
        userDefaults.removeObject(forKey: Keys.allLogs)
        userDefaults.removeObject(forKey: Keys.weeklyLogs)
    }
}
