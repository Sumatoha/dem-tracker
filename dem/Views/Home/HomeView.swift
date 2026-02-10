import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var onSettingsTapped: () -> Void = {}

    @State private var showHealthExplanation = false
    @State private var showSavingsExplanation = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 16)

                    // Counter Section
                    counterSection
                        .padding(.top, 24)

                    // Big Log Button
                    BigLogButton {
                        viewModel.onLogButtonTapped()
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)

                    // Activity Section
                    activitySection
                        .padding(.horizontal, Layout.horizontalPadding)

                    // Stats Cards
                    statsCardsSection
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.top, 20)

                    // Motivational Quote
                    quoteSection
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.top, 32)
                        .padding(.bottom, 120)
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
        .task {
            await viewModel.loadData()
            await viewModel.setupInitialNotifications()
        }
        .fullScreenCover(isPresented: $viewModel.showTriggerSelection) {
            TriggerSelectionView { trigger in
                Task {
                    await viewModel.submitLog(trigger: trigger)
                }
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Произошла ошибка")
        }
        .sheet(isPresented: $showHealthExplanation) {
            HealthExplanationView(
                hoursSinceLastLog: viewModel.hoursSinceLastLog,
                healthStatus: viewModel.healthStatus
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSavingsExplanation) {
            SavingsExplanationView(
                todaySavings: viewModel.todaySavings,
                baseline: viewModel.profile?.safeBaselinePerDay ?? 10,
                todayCount: viewModel.todayCount,
                pricePerUnit: viewModel.profile?.pricePerUnit ?? 12.5
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.primaryAccent)
                    .frame(width: 12, height: 12)

                Text("dem")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            Button {
                Haptics.selection()
                onSettingsTapped()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - Counter Section

    private var counterSection: some View {
        VStack(spacing: 8) {
            Text("СЕГОДНЯ")
                .font(.sectionLabel)
                .kerning(3)
                .foregroundColor(.textSecondary)

            // Счётчик с лимитом если программа активна
            if let limit = viewModel.currentDailyLimit {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(viewModel.todayCount)")
                        .font(.giantCounter)
                        .foregroundColor(viewModel.isOverLimit ? Color(hex: "FF6B6B") : .textPrimary)
                        .contentTransition(.numericText())

                    Text("/\(limit)")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            } else {
                Text("\(viewModel.todayCount)")
                    .font(.giantCounter)
                    .foregroundColor(.textPrimary)
                    .contentTransition(.numericText())
            }

            TimerPillView(lastLogDate: viewModel.lastLogDate)
                .padding(.top, 4)

            Text("С ПОСЛЕДНЕЙ")
                .font(.system(size: 13, weight: .medium))
                .kerning(2)
                .foregroundColor(.textSecondary)
                .padding(.top, 6)
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("АКТИВНОСТЬ")
                    .font(.sectionLabel)
                    .kerning(2)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("СРЕДНЕЕ: \(String(format: "%.1f", viewModel.averagePerDay))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primaryAccent)
            }

            ActivityChart(
                data: viewModel.dailyCounts,
                dailyLimit: viewModel.currentDailyLimit
            )
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.selection()
                showSavingsExplanation = true
            } label: {
                StatCard(
                    title: "ЭКОНОМИЯ",
                    value: "\(viewModel.todaySavings)",
                    suffix: "₸",
                    style: .light
                )
            }
            .buttonStyle(.plain)

            Button {
                Haptics.selection()
                showHealthExplanation = true
            } label: {
                StatCard(
                    title: "ЗДОРОВЬЕ",
                    value: viewModel.healthStatusText,
                    icon: viewModel.healthStatusIcon,
                    style: .light
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        Text("«\(viewModel.motivationalQuote)»")
            .font(.system(size: 15, weight: .regular, design: .serif))
            .italic()
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

}

// MARK: - Health Explanation View

struct HealthExplanationView: View {
    let hoursSinceLastLog: Double
    let healthStatus: HealthStatus

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current status
                    VStack(spacing: 12) {
                        Image(systemName: healthStatus.icon)
                            .font(.system(size: 48))
                            .foregroundColor(healthStatus.color)

                        Text(healthStatus.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(healthStatus.description)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    Divider()

                    // Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как восстанавливается организм")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        ForEach(HealthMilestone.all, id: \.hours) { milestone in
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(hoursSinceLastLog >= milestone.hours ? Color.primaryAccent : Color.cardFill)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(milestone.timeLabel)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(hoursSinceLastLog >= milestone.hours ? .primaryAccent : .textPrimary)

                                    Text(milestone.benefit)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Здоровье")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Savings Explanation View

struct SavingsExplanationView: View {
    let todaySavings: Int
    let baseline: Int
    let todayCount: Int
    let pricePerUnit: Double

    @Environment(\.dismiss) private var dismiss

    var savedCount: Int {
        max(0, baseline - todayCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current savings
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.primaryAccent)

                        Text("\(todaySavings) ₸")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text("сэкономлено сегодня")
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    Divider()

                    // Calculation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как считается")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            calculationRow(
                                label: "Обычно выкуриваешь",
                                value: "\(baseline) шт/день"
                            )

                            calculationRow(
                                label: "Сегодня выкурил",
                                value: "\(todayCount) шт"
                            )

                            calculationRow(
                                label: "Сэкономил",
                                value: "\(savedCount) шт"
                            )

                            calculationRow(
                                label: "Цена за штуку",
                                value: "\(String(format: "%.0f", pricePerUnit)) ₸"
                            )

                            Divider()

                            HStack {
                                Text("Итого")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("\(savedCount) × \(String(format: "%.0f", pricePerUnit)) = \(todaySavings) ₸")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Note
                    Text("Экономия растёт, когда ты куришь меньше своей нормы. Чем меньше сигарет — тем больше денег остаётся.")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding(16)
                        .background(Color.primaryAccent.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Экономия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }

    private func calculationRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Health Models

enum HealthStatus {
    case veryRecent      // 0-1 час
    case recent          // 1-2 часа
    case recovering      // 2-8 часов
    case improving       // 8-24 часа
    case strong          // 24-72 часа
    case excellent       // 72+ часов

    var title: String {
        switch self {
        case .veryRecent: return "Начало пути"
        case .recent: return "Первые шаги"
        case .recovering: return "Восстановление"
        case .improving: return "Улучшение"
        case .strong: return "Отлично!"
        case .excellent: return "Превосходно!"
        }
    }

    var description: String {
        switch self {
        case .veryRecent:
            return "Организм только начинает очищаться. Каждый час без сигареты — это победа."
        case .recent:
            return "Никотин начинает выводиться из крови. Продолжай!"
        case .recovering:
            return "Уровень угарного газа снижается, кислород лучше поступает к органам."
        case .improving:
            return "Кровообращение улучшается, лёгкие начинают очищаться."
        case .strong:
            return "Нервные окончания восстанавливаются. Вкус и запах становятся ярче!"
        case .excellent:
            return "Дыхание стало легче, энергии больше. Ты на правильном пути!"
        }
    }

    var icon: String {
        switch self {
        case .veryRecent: return "leaf"
        case .recent: return "leaf.fill"
        case .recovering: return "heart"
        case .improving: return "heart.fill"
        case .strong: return "star.fill"
        case .excellent: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .veryRecent: return .textSecondary
        case .recent: return .primaryAccent.opacity(0.6)
        case .recovering: return .primaryAccent
        case .improving: return .primaryAccent
        case .strong: return Color(hex: "4CAF50")
        case .excellent: return Color(hex: "4CAF50")
        }
    }

    var statusText: String {
        switch self {
        case .veryRecent: return "+5%"
        case .recent: return "+15%"
        case .recovering: return "+30%"
        case .improving: return "+60%"
        case .strong: return "+85%"
        case .excellent: return "+95%"
        }
    }

    var statusIcon: String {
        switch self {
        case .veryRecent, .recent: return "arrow.up.right"
        case .recovering, .improving: return "heart.fill"
        case .strong, .excellent: return "star.fill"
        }
    }
}

struct HealthMilestone {
    let hours: Double
    let timeLabel: String
    let benefit: String

    static let all: [HealthMilestone] = [
        HealthMilestone(hours: 0.33, timeLabel: "20 минут", benefit: "Пульс и давление начинают нормализоваться"),
        HealthMilestone(hours: 2, timeLabel: "2 часа", benefit: "Никотин выводится из крови"),
        HealthMilestone(hours: 8, timeLabel: "8 часов", benefit: "Уровень кислорода в норме"),
        HealthMilestone(hours: 24, timeLabel: "24 часа", benefit: "Риск сердечного приступа снижается"),
        HealthMilestone(hours: 48, timeLabel: "48 часов", benefit: "Нервные окончания восстанавливаются"),
        HealthMilestone(hours: 72, timeLabel: "72 часа", benefit: "Дышать становится легче"),
    ]
}

#Preview {
    HomeView()
}
