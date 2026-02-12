import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Evening Summary (user's chosen time)

    func scheduleEveningSummary(
        hour: Int = 22,
        minute: Int = 0,
        todayCount: Int,
        limit: Int?
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["evening_summary"])

        let content = UNMutableNotificationContent()
        content.title = L.Notifications.eveningTitle
        content.sound = .default

        if todayCount == 0 {
            content.body = L.Notifications.eveningZero
        } else if let limit = limit {
            if todayCount < limit {
                content.body = L.Notifications.eveningUnderLimit(todayCount, limit)
            } else if todayCount == limit {
                content.body = L.Notifications.eveningAtLimit(todayCount, limit)
            } else {
                content.body = L.Notifications.eveningOverLimit(todayCount, limit)
            }
        } else {
            content.body = L.Notifications.eveningNoLimit(todayCount)
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Limit Exceeded (sent 1 minute after exceeding)

    func sendLimitExceededNotification(limit: Int) {
        let content = UNMutableNotificationContent()
        content.title = L.Notifications.limitExceededTitle
        content.body = L.Notifications.limitExceededBody(limit)
        content.sound = .default

        // Send after 1 minute
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "limit_exceeded_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Health Milestones (2h, 6h, 12h, 24h, 72h)

    func scheduleHealthMilestones(lastLogDate: Date) {
        let ids = ["milestone_2h", "milestone_6h", "milestone_12h", "milestone_24h", "milestone_72h"]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)

        let milestones: [(id: String, hours: Double, title: String, body: String)] = [
            ("milestone_2h", 2, L.Notifications.milestone2h, L.Notifications.milestone2hBody),
            ("milestone_6h", 6, L.Notifications.milestone6h, L.Notifications.milestone6hBody),
            ("milestone_12h", 12, L.Notifications.milestone12h, L.Notifications.milestone12hBody),
            ("milestone_24h", 24, L.Notifications.milestone24h, L.Notifications.milestone24hBody),
            ("milestone_72h", 72, L.Notifications.milestone72h, L.Notifications.milestone72hBody),
        ]

        for m in milestones {
            let fireDate = lastLogDate.addingTimeInterval(m.hours * 3600)
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = m.title
            content.body = m.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: fireDate.timeIntervalSinceNow,
                repeats: false
            )
            let request = UNNotificationRequest(identifier: m.id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Schedule All (called when app loads or after logging)

    func scheduleNotifications(
        eveningHour: Int,
        eveningMinute: Int,
        todayCount: Int,
        dailyLimit: Int?,
        lastLogDate: Date?
    ) {
        // Schedule evening summary
        scheduleEveningSummary(
            hour: eveningHour,
            minute: eveningMinute,
            todayCount: todayCount,
            limit: dailyLimit
        )

        // Schedule health milestones if we have a last log date
        if let lastLog = lastLogDate {
            scheduleHealthMilestones(lastLogDate: lastLog)
        }
    }

    // MARK: - Cancel

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func cancelMilestones() {
        let ids = ["milestone_2h", "milestone_6h", "milestone_12h", "milestone_24h", "milestone_72h"]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Helpers

    func parseTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return (22, 0)
        }
        return (hour, minute)
    }
}
