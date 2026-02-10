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

    // MARK: - Morning Notification (10:00)

    func scheduleMorningMotivation(
        hour: Int = 10,
        minute: Int = 0,
        dailyLimit: Int?,
        streakDays: Int = 0
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["morning_motivation"])

        let content = UNMutableNotificationContent()
        content.sound = .default

        // Разные сообщения для разнообразия
        let messages: [(title: String, body: String)]

        if let limit = dailyLimit {
            if streakDays > 0 {
                messages = [
                    ("Доброе утро", "Уже \(streakDays) дн. в рамках плана. Сегодня лимит: \(limit)."),
                    ("Новый день", "Твой план на сегодня: до \(limit). Ты справишься!"),
                    ("Начинаем", "Лимит сегодня: \(limit). Серия: \(streakDays) дн."),
                ]
            } else {
                messages = [
                    ("Доброе утро", "Сегодня новый день. Твой лимит: \(limit)."),
                    ("Новый день", "План на сегодня: до \(limit). Удачи!"),
                    ("Начинаем", "Цель дня: не больше \(limit). Ты сможешь!"),
                ]
            }
        } else {
            messages = [
                ("Доброе утро", "Отслеживай каждую сигарету — это первый шаг."),
                ("Новый день", "Записывай всё, чтобы видеть прогресс."),
                ("Начинаем", "Осознанность — ключ к изменениям."),
            ]
        }

        let random = messages.randomElement()!
        content.title = random.title
        content.body = random.body

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_motivation", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Mid-day Check (14:00)

    func scheduleMidDayCheck(
        hour: Int = 14,
        minute: Int = 0,
        currentCount: Int,
        dailyLimit: Int?
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["midday_check"])

        guard let limit = dailyLimit else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        // Расчёт: к 14:00 должно быть использовано ~60% лимита (14/24 часов)
        let expectedByNow = Double(limit) * 0.6
        let remaining = limit - currentCount

        if currentCount == 0 {
            content.title = "Отличное начало"
            content.body = "Ещё ни одной сегодня. Продолжай!"
        } else if Double(currentCount) <= expectedByNow {
            content.title = "Идёшь по плану"
            content.body = "\(currentCount) из \(limit). Осталось \(remaining) до конца дня."
        } else if currentCount >= limit {
            content.title = "Лимит достигнут"
            content.body = "Уже \(currentCount) из \(limit). Попробуй остановиться."
        } else {
            content.title = "Проверка дня"
            content.body = "\(currentCount) из \(limit). Осталось \(remaining) — распредели до вечера."
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false) // Не повторяется - обновляется каждый день
        let request = UNNotificationRequest(identifier: "midday_check", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Evening Summary

    func scheduleEveningSummary(
        hour: Int = 22,
        minute: Int = 0,
        todayCount: Int,
        limit: Int?,
        yesterdayCount: Int?
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["evening_summary"])

        let content = UNMutableNotificationContent()
        content.sound = .default

        if todayCount == 0 {
            content.title = "Невероятный день"
            content.body = "0 сегодня. Так держать!"
        } else if let limit = limit, todayCount <= limit {
            let diff = limit - todayCount
            if diff > 0 {
                content.title = "План выполнен"
                content.body = "\(todayCount) из \(limit). Даже \(diff) в запасе!"
            } else {
                content.title = "Точно в цель"
                content.body = "\(todayCount) из \(limit). Ровно по плану."
            }
        } else if let limit = limit {
            let over = todayCount - limit
            content.title = "Итог дня"
            content.body = "\(todayCount) из \(limit) (+\(over)). Ничего, завтра новый день."
        } else if let yesterday = yesterdayCount {
            if todayCount < yesterday {
                content.title = "Прогресс"
                content.body = "Сегодня \(todayCount) — на \(yesterday - todayCount) меньше чем вчера."
            } else if todayCount == yesterday {
                content.title = "Итог дня"
                content.body = "Сегодня \(todayCount), как и вчера."
            } else {
                content.title = "Итог дня"
                content.body = "Сегодня \(todayCount). Завтра попробуй меньше."
            }
        } else {
            content.title = "Итог дня"
            content.body = "Сегодня: \(todayCount). Записано!"
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Instant Feedback (after logging)

    func sendInstantFeedback(currentCount: Int, dailyLimit: Int?) {
        guard let limit = dailyLimit else { return }

        // Уведомление только в критические моменты
        let content = UNMutableNotificationContent()
        content.sound = .default

        if currentCount == limit {
            // Достиг лимита
            content.title = "Лимит на сегодня"
            content.body = "Это была последняя по плану. Попробуй продержаться до завтра."
        } else if currentCount == limit + 1 {
            // Первое превышение
            content.title = "Лимит превышен"
            content.body = "\(currentCount) из \(limit). Ещё можно остановиться."
        } else {
            // Не отправляем уведомление для обычных логов
            return
        }

        // Отправляем через 1 секунду (чтобы не мешать UI)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "instant_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Summary (Sunday 21:00)

    func scheduleWeeklySummary(
        weekTotal: Int,
        weekAverage: Double,
        previousWeekTotal: Int?,
        moneySaved: Int?
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = "Итоги недели"

        var body = "Среднее: \(String(format: "%.1f", weekAverage))/день."

        if let prev = previousWeekTotal, prev > 0 {
            let diff = prev - weekTotal
            if diff > 0 {
                body += " На \(diff) меньше прошлой недели!"
            } else if diff < 0 {
                body += " На \(-diff) больше прошлой недели."
            }
        }

        if let saved = moneySaved, saved > 0 {
            body += " Сэкономлено: \(saved)₸."
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

    // MARK: - Health Milestones

    func scheduleHealthMilestones(lastLogDate: Date) {
        let ids = ["milestone_2h", "milestone_8h", "milestone_24h", "milestone_48h", "milestone_72h"]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ids)

        let milestones: [(id: String, hours: Double, title: String, body: String)] = [
            ("milestone_2h", 2, "2 часа", "Никотин начинает выводиться из крови."),
            ("milestone_8h", 8, "8 часов", "Уровень кислорода в крови нормализуется."),
            ("milestone_24h", 24, "Сутки!", "Риск сердечного приступа начал снижаться."),
            ("milestone_48h", 48, "2 дня!", "Нервные окончания восстанавливаются."),
            ("milestone_72h", 72, "3 дня!", "Дыхание стало легче."),
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

    // MARK: - Schedule All Daily Notifications

    /// Вызывать при включении уведомлений и при каждом логе
    func scheduleAllDailyNotifications(
        morningHour: Int = 10,
        eveningHour: Int,
        eveningMinute: Int,
        todayCount: Int,
        dailyLimit: Int?,
        yesterdayCount: Int?,
        streakDays: Int = 0
    ) {
        // Утреннее
        scheduleMorningMotivation(
            hour: morningHour,
            minute: 0,
            dailyLimit: dailyLimit,
            streakDays: streakDays
        )

        // Дневная проверка (14:00)
        scheduleMidDayCheck(
            hour: 14,
            minute: 0,
            currentCount: todayCount,
            dailyLimit: dailyLimit
        )

        // Вечерний отчёт
        scheduleEveningSummary(
            hour: eveningHour,
            minute: eveningMinute,
            todayCount: todayCount,
            limit: dailyLimit,
            yesterdayCount: yesterdayCount
        )
    }

    // MARK: - Cancel

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func cancelScheduled() {
        // Отменяет только запланированные, оставляет health milestones если нужно
        let scheduledIds = ["morning_motivation", "midday_check", "evening_summary", "weekly_summary"]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: scheduledIds)
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
