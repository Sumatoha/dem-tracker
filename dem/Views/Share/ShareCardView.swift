import SwiftUI

struct ShareCardView: View {
    let stats: ShareStats

    // Colors - brighter
    private let bgDark = Color(red: 0.08, green: 0.08, blue: 0.10)
    private let cardBg = Color(red: 0.16, green: 0.16, blue: 0.18)
    private let accentOrange = Color(red: 1.0, green: 0.45, blue: 0.25)

    var body: some View {
        ZStack {
            bgDark

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Logo
                logoSection

                Spacer().frame(height: 50)

                // Main stat
                mainStatSection

                Spacer().frame(height: 40)

                // Secondary stats
                secondaryStatsSection

                Spacer().frame(height: 40)

                // Chart - full width
                weeklyChartSection

                Spacer()

                // Footer
                footerSection

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Logo

    private var logoSection: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 5)
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 5)
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(Color.white.opacity(0.55), lineWidth: 5)
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(accentOrange)
                    .frame(width: 18, height: 18)
            }

            Text("dem")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Main Stat

    private var mainStatSection: some View {
        VStack(spacing: 20) {
            // Today label
            Text("СЕГОДНЯ")
                .font(.system(size: 28, weight: .semibold))
                .tracking(4)
                .foregroundColor(.white.opacity(0.5))

            // Count
            HStack(alignment: .firstTextBaseline, spacing: 20) {
                Text("\(stats.todaySmoked)")
                    .font(.system(size: 200, weight: .bold))
                    .foregroundColor(.white)

                Text(cigaretteWord(stats.todaySmoked))
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .offset(y: -20)
            }

            // Comparison badge
            if stats.percentVsLastMonth != 0 || stats.lastMonthAverage > 0 {
                HStack(spacing: 14) {
                    if stats.percentVsLastMonth != 0 {
                        Image(systemName: stats.percentVsLastMonth < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 36, weight: .bold))
                    }

                    Text(stats.comparisonText)
                        .font(.system(size: 36, weight: .semibold))
                }
                .foregroundColor(stats.percentVsLastMonth <= 0 ? Color.green : accentOrange)
                .padding(.horizontal, 36)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(stats.percentVsLastMonth <= 0 ? Color.green.opacity(0.18) : accentOrange.opacity(0.18))
                )
            }
        }
    }

    private func cigaretteWord(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 {
            return "сигарет"
        }
        switch mod10 {
        case 1: return "сигарета"
        case 2, 3, 4: return "сигареты"
        default: return "сигарет"
        }
    }

    // MARK: - Secondary Stats

    private var secondaryStatsSection: some View {
        HStack(spacing: 24) {
            statCard(
                icon: "clock.fill",
                value: stats.recordTimeText,
                label: "рекорд\nбез сигарет"
            )

            statCard(
                icon: "calendar",
                value: "\(stats.daysTracking)",
                label: daysWord(stats.daysTracking)
            )
        }
    }

    private func daysWord(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 {
            return "дней\nв dem"
        }
        switch mod10 {
        case 1: return "день\nв dem"
        case 2, 3, 4: return "дня\nв dem"
        default: return "дней\nв dem"
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(accentOrange)

            Text(value)
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(cardBg)
        )
    }

    // MARK: - Weekly Chart (full width)

    private var weeklyChartSection: some View {
        VStack(spacing: 28) {
            Text("ПОСЛЕДНИЕ 7 ДНЕЙ")
                .font(.system(size: 24, weight: .semibold))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    chartBar(index: index)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(cardBg)
        )
    }

    private func chartBar(index: Int) -> some View {
        let count = stats.dailyCounts[safe: index] ?? 0
        let maxCount = max(stats.dailyCounts.max() ?? 1, 1)
        let barHeight = max(20, CGFloat(count) / CGFloat(maxCount) * 130)
        let isToday = index == 6
        let label = stats.dayLabels[safe: index] ?? ""

        return VStack(spacing: 14) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isToday ? accentOrange : .white.opacity(0.7))

            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? accentOrange : Color.white.opacity(0.25))
                .frame(width: 56, height: barHeight)

            Text(label)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Отслеживаю прогресс в")
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text("dem")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(accentOrange)
        }
    }
}

// MARK: - Share Stats Model

struct ShareStats {
    let todaySmoked: Int
    let lastMonthAverage: Double
    let percentVsLastMonth: Int
    let recordHours: Int
    let recordMinutes: Int
    let daysTracking: Int
    let dailyCounts: [Int]
    let dayLabels: [String]

    var comparisonText: String {
        if percentVsLastMonth == 0 {
            return "как обычно"
        } else if percentVsLastMonth < 0 {
            return "\(abs(percentVsLastMonth))% меньше нормы"
        } else {
            return "\(percentVsLastMonth)% больше нормы"
        }
    }

    var recordTimeText: String {
        if recordHours >= 48 {
            let days = recordHours / 24
            return "\(days) дн"
        } else if recordHours >= 24 {
            let days = recordHours / 24
            let hours = recordHours % 24
            if hours > 0 {
                return "\(days)д \(hours)ч"
            }
            return "1 день"
        } else if recordHours > 0 {
            return "\(recordHours) ч"
        } else if recordMinutes > 0 {
            return "\(recordMinutes) мин"
        } else {
            return "—"
        }
    }
}

// MARK: - Array Safe Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview(traits: .fixedLayout(width: 360, height: 640)) {
    ShareCardView(stats: ShareStats(
        todaySmoked: 4,
        lastMonthAverage: 8.5,
        percentVsLastMonth: -53,
        recordHours: 14,
        recordMinutes: 30,
        daysTracking: 12,
        dailyCounts: [8, 6, 7, 5, 4, 6, 4],
        dayLabels: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    ))
    .scaleEffect(0.33)
}
