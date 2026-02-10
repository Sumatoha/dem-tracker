import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var logs: [SmokingLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedDate: Date = Date()

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

    var monthlyCount: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()

        return logs.filter { $0.createdAt >= startOfMonth }.count
    }

    var cleanDays: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let today = calendar.startOfDay(for: Date())

        guard let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: today).day else {
            return 0
        }

        let daysWithLogs = Set(logs.compactMap { log -> Date? in
            guard log.createdAt >= startOfMonth else { return nil }
            return calendar.startOfDay(for: log.createdAt)
        })

        return max(0, daysInMonth + 1 - daysWithLogs.count)
    }

    func loadData() async {
        // Fetch fresh data from server
        do {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: selectedDate)
            ) ?? selectedDate

            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                return
            }

            let freshLogs = try await supabase.fetchLogsForDateRange(from: startOfMonth, to: endOfMonth)
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
        formatter.locale = Locale(identifier: "ru_RU")

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'СЕГОДНЯ,' d MMMM"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'ВЧЕРА,' d MMMM"
        } else {
            formatter.dateFormat = "EEEE, d MMMM"
        }

        return formatter.string(from: date).uppercased()
    }

    func intervalSincePrevious(for log: SmokingLog, in dayLogs: [SmokingLog]) -> String? {
        guard let index = dayLogs.firstIndex(where: { $0.id == log.id }),
              index < dayLogs.count - 1 else {
            return nil
        }

        let previousLog = dayLogs[index + 1]
        let interval = log.createdAt.timeIntervalSince(previousLog.createdAt)

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        return String(format: "%02d:%02d", hours, minutes)
    }
}
