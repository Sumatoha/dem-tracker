import Foundation

/// Manages shared data between app and widget via App Groups
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let suiteName = "group.com.dem.shared"
    private let userDefaults: UserDefaults?

    private enum Keys {
        static let todayCount = "widget_today_count"
        static let todayDate = "widget_today_date"
        static let pendingLogs = "widget_pending_logs"
        static let userId = "widget_user_id"
        static let productType = "widget_product_type"
    }

    private init() {
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Today Count

    func getTodayCount() -> Int {
        guard let userDefaults = userDefaults else { return 0 }

        // Check if count is from today
        let savedDate = userDefaults.double(forKey: Keys.todayDate)
        let savedDateObj = Date(timeIntervalSince1970: savedDate)

        if !Calendar.current.isDateInToday(savedDateObj) {
            // Reset for new day
            userDefaults.set(0, forKey: Keys.todayCount)
            userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.todayDate)
            return 0
        }

        return userDefaults.integer(forKey: Keys.todayCount)
    }

    func setTodayCount(_ count: Int) {
        userDefaults?.set(count, forKey: Keys.todayCount)
        userDefaults?.set(Date().timeIntervalSince1970, forKey: Keys.todayDate)
    }

    func incrementTodayCount() {
        let current = getTodayCount()
        setTodayCount(current + 1)
    }

    // MARK: - Pending Logs (for syncing when app opens)

    struct PendingLog: Codable {
        let timestamp: Date
        let productType: String?
    }

    func addPendingLog() {
        var pending = getPendingLogs()
        let productType = userDefaults?.string(forKey: Keys.productType)
        pending.append(PendingLog(timestamp: Date(), productType: productType))
        savePendingLogs(pending)
    }

    func getPendingLogs() -> [PendingLog] {
        guard let data = userDefaults?.data(forKey: Keys.pendingLogs),
              let logs = try? JSONDecoder().decode([PendingLog].self, from: data) else {
            return []
        }
        return logs
    }

    func clearPendingLogs() {
        userDefaults?.removeObject(forKey: Keys.pendingLogs)
    }

    private func savePendingLogs(_ logs: [PendingLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            userDefaults?.set(data, forKey: Keys.pendingLogs)
        }
    }

    // MARK: - User Info (set by main app)

    func setUserId(_ id: String?) {
        userDefaults?.set(id, forKey: Keys.userId)
    }

    func getUserId() -> String? {
        userDefaults?.string(forKey: Keys.userId)
    }

    func setProductType(_ type: String?) {
        userDefaults?.set(type, forKey: Keys.productType)
    }

    func getProductType() -> String? {
        userDefaults?.string(forKey: Keys.productType)
    }
}
