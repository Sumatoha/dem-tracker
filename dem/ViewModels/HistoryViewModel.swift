import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var logs: [SmokingLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let supabase = SupabaseManager.shared
    private let cache = CacheManager.shared

    init() {
        // Load cache synchronously on init - no flash
        if let cachedLogs = cache.getCachedAllLogs() {
            logs = cachedLogs
        }
    }

    var groupedLogs: [(date: Date, logs: [SmokingLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.createdAt)
        }

        return grouped
            .map { (date: $0.key, logs: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.date > $1.date }
    }

    private var last30DaysStart: Date {
        Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    var monthlyCount: Int {
        return logs.filter { $0.createdAt >= last30DaysStart }.count
    }

    var cleanDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let daysWithLogs = Set(logs.compactMap { log -> Date? in
            guard log.createdAt >= last30DaysStart else { return nil }
            return calendar.startOfDay(for: log.createdAt)
        })

        return max(0, 30 - daysWithLogs.count)
    }

    func loadData() async {
        // Fetch fresh data from server — last 30 days
        do {
            let now = Date()
            let freshLogs = try await supabase.fetchLogsForDateRange(from: last30DaysStart, to: now)
            logs = freshLogs

            // Update cache in background
            cache.cacheAllLogs(freshLogs)
        } catch {
            if logs.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "d MMMM"
            return "\(L.History.today), \(formatter.string(from: date))".uppercased()
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "d MMMM"
            return "\(L.History.yesterday), \(formatter.string(from: date))".uppercased()
        } else {
            formatter.dateFormat = "EEEE, d MMMM"
            return formatter.string(from: date).uppercased()
        }
    }

    func intervalSincePrevious(for log: SmokingLog, in dayLogs: [SmokingLog]) -> String? {
        // Ищем предыдущий лог во ВСЕХ логах, не только в текущем дне
        // Это исправляет случай: 23:59 вчера → 00:10 сегодня = 11 минут, а не nil
        let allLogsSorted = logs.sorted { $0.createdAt > $1.createdAt }

        guard let currentIndex = allLogsSorted.firstIndex(where: { $0.id == log.id }),
              currentIndex < allLogsSorted.count - 1 else {
            return nil
        }

        let previousLog = allLogsSorted[currentIndex + 1]
        let interval = log.createdAt.timeIntervalSince(previousLog.createdAt)

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        return String(format: "%02d:%02d", hours, minutes)
    }
}
