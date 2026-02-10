import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Проверить текущий статус разрешений
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Запланировать ежедневное вечернее уведомление
    func scheduleDailySummary(
        hour: Int = 22,
        minute: Int = 0,
        todayCount: Int,
        limit: Int?,
        yesterdayCount: Int?
    ) {
        // Удалить предыдущее
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_summary"])

        let content = UNMutableNotificationContent()
        content.sound = .default

        // Формируем текст
        if todayCount == 0 {
            content.title = "Невероятный день"
            content.body = "0 сегодня. Так держать"
        } else if let limit = limit, todayCount <= limit {
            content.title = "План выполнен"
            content.body = "Сегодня \(todayCount) из \(limit). В рамках плана."
        } else if let limit = limit {
            content.title = "Итог дня"
            content.body = "Сегодня \(todayCount) из \(limit). Ничего — завтра новый день."
        } else if let yesterday = yesterdayCount, todayCount < yesterday {
            content.title = "Прогресс"
            content.body = "Сегодня \(todayCount) — на \(yesterday - todayCount) меньше чем вчера."
        } else {
            content.title = "Итог дня"
            content.body = "Сегодня: \(todayCount)."
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// Еженедельный отчёт (воскресенье вечер)
    func scheduleWeeklySummary(
        weekAverage: Double,
        weekTotal: Int,
        weekSpent: Int,
        previousWeekTotal: Int?,
        newLimit: Int?
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = "Итоги недели"

        var body = "Среднее: \(String(format: "%.1f", weekAverage))/день. Потрачено: \(weekSpent)₸."
        if let prev = previousWeekTotal {
            let diff = prev - weekTotal
            if diff > 0 {
                body += " На \(diff) меньше чем на прошлой неделе"
            }
        }
        if let limit = newLimit {
            body += " Новый ориентир — \(limit)/день."
        }
        content.body = body

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Воскресенье
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// Milestone здоровья (одноразовые, по таймеру)
    func scheduleHealthMilestone(lastLogDate: Date) {
        // Удалить все предыдущие milestone
        let ids = ["milestone_2h", "milestone_8h", "milestone_24h", "milestone_72h"]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)

        let milestones: [(id: String, hours: Double, title: String, body: String)] = [
            ("milestone_2h", 2, "2 часа", "Никотин начинает выводиться из крови."),
            ("milestone_8h", 8, "8 часов", "Уровень кислорода в крови нормализован."),
            ("milestone_24h", 24, "Сутки без никотина!", "Лёгкие начали восстанавливаться."),
            ("milestone_72h", 72, "3 дня!", "Дыхание стало заметно легче."),
        ]

        for m in milestones {
            let fireDate = lastLogDate.addingTimeInterval(m.hours * 3600)
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = m.title
            content.body = m.body
            content.sound = .default

            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: m.id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Удалить все уведомления
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Парсинг времени из строки "HH:mm"
    func parseTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return (22, 0) // Default
        }
        return (hour, minute)
    }
}
