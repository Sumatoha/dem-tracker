import SwiftUI
import UIKit

@MainActor
class ShareManager {

    /// Генерирует изображение карточки и открывает меню шеринга
    static func shareProgress(stats: ShareStats, from viewController: UIViewController? = nil) {
        let cardView = ShareCardView(stats: stats)

        // Рендерим SwiftUI view в изображение
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0 // 3x для высокого качества

        guard let image = renderer.uiImage else {
            print("Failed to render share card")
            return
        }

        // Открываем системное меню шеринга
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Исключаем ненужные опции
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        // Получаем текущий ViewController
        if let vc = viewController ?? Self.topViewController() {
            // Для iPad нужно указать sourceView
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = vc.view
                popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            vc.present(activityVC, animated: true)
        }
    }

    /// Сохраняет изображение в галерею
    static func saveToPhotos(stats: ShareStats, completion: @escaping (Bool) -> Void) {
        let cardView = ShareCardView(stats: stats)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0

        guard let image = renderer.uiImage else {
            completion(false)
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true)
    }

    /// Шеринг напрямую в Instagram Stories
    static func shareToInstagramStories(stats: ShareStats) {
        let cardView = ShareCardView(stats: stats)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0

        guard let image = renderer.uiImage,
              let imageData = image.pngData() else {
            print("Failed to render share card for Instagram")
            return
        }

        // Instagram Stories URL Scheme
        let urlScheme = URL(string: "instagram-stories://share?source_application=com.dem-tracker.dem")

        guard let url = urlScheme,
              UIApplication.shared.canOpenURL(url) else {
            // Instagram не установлен — используем обычный шеринг
            shareProgress(stats: stats)
            return
        }

        // Копируем изображение в pasteboard для Instagram
        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]

        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5) // 5 минут
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

        UIApplication.shared.open(url)
    }

    /// Получает верхний ViewController
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = window.rootViewController else {
            return nil
        }

        while let presented = topController.presentedViewController {
            topController = presented
        }

        return topController
    }
}

// MARK: - Stats Calculator

extension ShareManager {

    /// Вычисляет статистику для шеринга на основе логов
    static func calculateStats(logs: [SmokingLog]) -> ShareStats {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // 1. Сегодня выкурено
        let todayLogs = logs.filter { calendar.isDateInToday($0.createdAt) }
        let todaySmoked = todayLogs.count

        // 2. Среднее за прошлый месяц (30 дней назад, исключая сегодня)
        guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return defaultStats(todaySmoked: todaySmoked)
        }

        let lastMonthLogs = logs.filter { log in
            log.createdAt >= monthAgo && log.createdAt < today
        }

        let lastMonthAverage: Double
        if lastMonthLogs.isEmpty {
            lastMonthAverage = 0
        } else {
            // Группируем по дням
            var dailyCounts: [Date: Int] = [:]
            for log in lastMonthLogs {
                let day = calendar.startOfDay(for: log.createdAt)
                dailyCounts[day, default: 0] += 1
            }
            let totalDays = dailyCounts.count
            lastMonthAverage = totalDays > 0 ? Double(lastMonthLogs.count) / Double(totalDays) : 0
        }

        // 3. Процент сравнения с прошлым месяцем
        let percentVsLastMonth: Int
        if lastMonthAverage > 0 {
            let diff = Double(todaySmoked) - lastMonthAverage
            percentVsLastMonth = Int(round(diff / lastMonthAverage * 100))
        } else {
            percentVsLastMonth = 0
        }

        // 4. Рекорд без курения (максимальный промежуток между логами)
        let (recordHours, recordMinutes) = calculateRecordWithoutSmoking(logs: logs, now: now)

        // 5. Дней отслеживания
        let daysTracking: Int
        if let firstLog = logs.min(by: { $0.createdAt < $1.createdAt }) {
            let components = calendar.dateComponents([.day], from: firstLog.createdAt, to: now)
            daysTracking = max(1, (components.day ?? 0) + 1)
        } else {
            daysTracking = 1
        }

        // 6. Данные для графика (последние 7 дней включая сегодня)
        var dailyCounts: [Int] = []
        var dayLabels: [String] = []

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                dailyCounts.append(0)
                dayLabels.append("")
                continue
            }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

            let count = logs.filter { log in
                log.createdAt >= startOfDay && log.createdAt < endOfDay
            }.count

            dailyCounts.append(count)

            formatter.dateFormat = "EE"
            let label = String(formatter.string(from: date).prefix(2)).capitalized
            dayLabels.append(label)
        }

        return ShareStats(
            todaySmoked: todaySmoked,
            lastMonthAverage: lastMonthAverage,
            percentVsLastMonth: percentVsLastMonth,
            recordHours: recordHours,
            recordMinutes: recordMinutes,
            daysTracking: daysTracking,
            dailyCounts: dailyCounts,
            dayLabels: dayLabels
        )
    }

    /// Вычисляет рекордное время без курения
    private static func calculateRecordWithoutSmoking(logs: [SmokingLog], now: Date) -> (hours: Int, minutes: Int) {
        guard !logs.isEmpty else {
            return (0, 0)
        }

        // Сортируем логи по дате
        let sortedLogs = logs.sorted { $0.createdAt < $1.createdAt }

        var maxInterval: TimeInterval = 0

        // Находим максимальный промежуток между соседними логами
        for i in 1..<sortedLogs.count {
            let interval = sortedLogs[i].createdAt.timeIntervalSince(sortedLogs[i-1].createdAt)
            maxInterval = max(maxInterval, interval)
        }

        // Проверяем промежуток от последнего лога до сейчас
        if let lastLog = sortedLogs.last {
            let intervalToNow = now.timeIntervalSince(lastLog.createdAt)
            maxInterval = max(maxInterval, intervalToNow)
        }

        let totalMinutes = Int(maxInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        return (hours, minutes)
    }

    /// Дефолтная статистика когда нет данных
    private static func defaultStats(todaySmoked: Int) -> ShareStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")

        var dayLabels: [String] = []
        for daysAgo in (0...6).reversed() {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                formatter.dateFormat = "EE"
                let label = String(formatter.string(from: date).prefix(2)).capitalized
                dayLabels.append(label)
            } else {
                dayLabels.append("")
            }
        }

        return ShareStats(
            todaySmoked: todaySmoked,
            lastMonthAverage: 0,
            percentVsLastMonth: 0,
            recordHours: 0,
            recordMinutes: 0,
            daysTracking: 1,
            dailyCounts: [0, 0, 0, 0, 0, 0, todaySmoked],
            dayLabels: dayLabels
        )
    }
}
