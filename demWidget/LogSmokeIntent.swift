import AppIntents
import WidgetKit

struct LogSmokeIntent: AppIntent {
    static var title: LocalizedStringResource = "Записать сигарету"
    static var description = IntentDescription("Записывает одну сигарету")

    func perform() async throws -> some IntentResult {
        // Increment local counter
        SharedDataManager.shared.incrementTodayCount()

        // Add to pending logs queue (will sync when app opens)
        SharedDataManager.shared.addPendingLog()

        // Refresh widget
        WidgetCenter.shared.reloadTimelines(ofKind: "demWidget")

        return .result()
    }
}
