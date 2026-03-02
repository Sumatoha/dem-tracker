import Foundation
import WidgetKit

/// Manages shared data between app and widget via App Groups
final class WidgetDataManager {
    static let shared = WidgetDataManager()

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
        refreshWidget()
    }

    func incrementTodayCount() {
        let current = getTodayCount()
        setTodayCount(current + 1)
    }

    // MARK: - Pending Logs (for syncing widget logs to server)

    struct PendingLog: Codable {
        let timestamp: Date
        let productType: String?
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

    // MARK: - User Info (set by main app for widget to use)

    func setUserId(_ id: UUID?) {
        userDefaults?.set(id?.uuidString, forKey: Keys.userId)
    }

    func getUserId() -> UUID? {
        guard let string = userDefaults?.string(forKey: Keys.userId) else { return nil }
        return UUID(uuidString: string)
    }

    func setProductType(_ type: ProductType?) {
        userDefaults?.set(type?.rawValue, forKey: Keys.productType)
    }

    func getProductType() -> ProductType? {
        guard let string = userDefaults?.string(forKey: Keys.productType) else { return nil }
        return ProductType(rawValue: string)
    }

    // MARK: - Widget Refresh

    func refreshWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "demWidget")
    }
}
