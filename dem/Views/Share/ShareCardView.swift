import SwiftUI

struct ShareCardView: View {
    let weeklyStats: WeeklyShareStats

    // Colors
    private let bgDark = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let bgLight = Color(red: 0.18, green: 0.18, blue: 0.18)
    private let accentOrange = Color(red: 1.0, green: 0.42, blue: 0.21)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [bgDark, bgLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Logo and branding
                brandingSection

                Spacer()
                    .frame(height: 60)

                // Main stats
                statsSection

                Spacer()
                    .frame(height: 50)

                // Weekly chart
                weeklyChartSection

                Spacer()

                // Footer
                footerSection

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Branding

    private var brandingSection: some View {
        VStack(spacing: 16) {
            // App icon placeholder - circles like the logo
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 6)
                    .frame(width: 85, height: 85)

                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 6)
                    .frame(width: 55, height: 55)

                Circle()
                    .fill(accentOrange)
                    .frame(width: 30, height: 30)
            }

            Text("dem")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 40) {
            // Progress percentage - main stat
            VStack(spacing: 12) {
                Text(weeklyStats.progressText)
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(accentOrange)

                Text(weeklyStats.progressDescription)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Secondary stats row
            HStack(spacing: 60) {
                statItem(
                    value: weeklyStats.savedMoneyText,
                    label: "сэкономлено"
                )

                statItem(
                    value: "\(weeklyStats.daysInPlan)",
                    label: weeklyStats.daysInPlan == 1 ? "день в плане" :
                           weeklyStats.daysInPlan < 5 ? "дня в плане" : "дней в плане"
                )
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(spacing: 20) {
            Text("ПОСЛЕДНИЕ 7 ДНЕЙ")
                .font(.system(size: 24, weight: .semibold))
                .tracking(3)
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .bottom, spacing: 16) {
                ForEach(0..<7, id: \.self) { index in
                    chartBar(index: index)
                }
            }
            .frame(height: 200)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
    }

    // MARK: - Chart Bar

    private func chartBar(index: Int) -> some View {
        let count = weeklyStats.dailyCounts[safe: index] ?? 0
        let maxCount = max(weeklyStats.dailyCounts.max() ?? 1, 1)
        let barHeight = CGFloat(count) / CGFloat(maxCount) * 150
        let isToday = index == 6
        let label = weeklyStats.dayLabels[safe: index] ?? ""

        return VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? accentOrange : Color.white.opacity(0.3))
                .frame(width: 50, height: max(20, barHeight))

            Text(label)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            Text("Отслеживаю прогресс в dem")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("App Store")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Weekly Stats Model

struct WeeklyShareStats {
    let cigarettesReduced: Int        // На сколько меньше выкурено
    let percentageReduced: Int        // Процент снижения
    let savedMoney: Int               // Сэкономлено денег
    let daysInPlan: Int               // Дней в плане
    let dailyCounts: [Int]            // Количество по дням [пн, вт, ср, чт, пт, сб, вс]
    let dayLabels: [String]           // Метки дней

    var progressText: String {
        if percentageReduced > 0 {
            return "-\(percentageReduced)%"
        } else if percentageReduced < 0 {
            return "+\(abs(percentageReduced))%"
        } else {
            return "0%"
        }
    }

    var progressDescription: String {
        if percentageReduced > 0 {
            return "меньше за неделю"
        } else if percentageReduced < 0 {
            return "больше за неделю"
        } else {
            return "без изменений"
        }
    }

    var savedMoneyText: String {
        if savedMoney > 0 {
            return "+\(savedMoney)₸"
        } else {
            return "0₸"
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

#Preview {
    ShareCardView(weeklyStats: WeeklyShareStats(
        cigarettesReduced: 15,
        percentageReduced: 25,
        savedMoney: 1500,
        daysInPlan: 5,
        dailyCounts: [8, 6, 7, 5, 4, 6, 3],
        dayLabels: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    ))
    .previewLayout(.fixed(width: 540, height: 960))
}
