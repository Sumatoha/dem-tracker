import SwiftUI
import UIKit

@MainActor
class ShareManager {

    /// Генерирует изображение карточки и открывает меню шеринга
    static func shareProgress(stats: WeeklyShareStats, from viewController: UIViewController? = nil) {
        let cardView = ShareCardView(weeklyStats: stats)

        // Рендерим SwiftUI view в изображение
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1.0 // 1x для точного размера 1080x1920

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
    static func saveToPhotos(stats: WeeklyShareStats, completion: @escaping (Bool) -> Void) {
        let cardView = ShareCardView(weeklyStats: stats)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1.0

        guard let image = renderer.uiImage else {
            completion(false)
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true)
    }

    /// Шеринг напрямую в Instagram Stories
    static func shareToInstagramStories(stats: WeeklyShareStats) {
        let cardView = ShareCardView(weeklyStats: stats)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1.0

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
    static func calculateWeeklyStats(
        logs: [SmokingLog],
        baseline: Int,
        pricePerUnit: Double
    ) -> WeeklyShareStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Получаем даты последних 7 дней (без сегодня)
        var dailyCounts: [Int] = []
        var dayLabels: [String] = []
        var totalSmoked = 0

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")

        for daysAgo in (1...7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                dailyCounts.append(0)
                dayLabels.append("")
                continue
            }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

            // Считаем логи за этот день
            let count = logs.filter { log in
                log.createdAt >= startOfDay && log.createdAt < endOfDay
            }.count

            dailyCounts.append(count)
            totalSmoked += count

            // Метка дня (Пн, Вт, ...)
            formatter.dateFormat = "EE"
            let label = formatter.string(from: date).prefix(2).capitalized
            dayLabels.append(label)
        }

        // Ожидаемое количество за 7 дней
        let expected = baseline * 7

        // Процент снижения
        let percentageReduced: Int
        if expected > 0 {
            percentageReduced = Int(round(Double(expected - totalSmoked) / Double(expected) * 100))
        } else {
            percentageReduced = 0
        }

        // Сэкономлено денег
        let cigarettesReduced = max(0, expected - totalSmoked)
        let savedMoney = Int(Double(cigarettesReduced) * pricePerUnit)

        // Дней в плане (когда выкурил меньше или равно baseline)
        let daysInPlan = dailyCounts.filter { $0 <= baseline }.count

        return WeeklyShareStats(
            cigarettesReduced: cigarettesReduced,
            percentageReduced: percentageReduced,
            savedMoney: savedMoney,
            daysInPlan: daysInPlan,
            dailyCounts: dailyCounts,
            dayLabels: dayLabels
        )
    }
}
