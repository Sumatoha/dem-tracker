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

            if viewModel.isLoading && viewModel.profile == nil {
                // Initial loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(L.Common.loading)
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }
            } else {
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
        .alert(L.Common.error, isPresented: $viewModel.showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? L.Common.error)
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
            HStack(spacing: 10) {
                Image("DemLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

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
            Text(L.Home.today)
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

            Text(L.Home.sinceLastOne)
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
                Text(L.Home.activity)
                    .font(.sectionLabel)
                    .kerning(2)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(L.Home.average): \(String(format: "%.1f", viewModel.averagePerDay))")
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
                    title: L.Home.savings,
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
                    title: L.Home.health,
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

    var currentPercentage: Int {
        switch hoursSinceLastLog {
        case 0..<1: return 5
        case 1..<2: return 15
        case 2..<4: return 25
        case 4..<8: return 40
        case 8..<12: return 55
        case 12..<24: return 70
        case 24..<48: return 85
        default: return 95
        }
    }

    var timeSinceText: String {
        if hoursSinceLastLog >= 999 {
            return L.Time.longAgo
        } else if hoursSinceLastLog < 1 {
            let minutes = Int(hoursSinceLastLog * 60)
            return L.Time.minutesAgo(max(1, minutes))
        } else if hoursSinceLastLog < 24 {
            return L.Time.hoursAgo(Int(hoursSinceLastLog))
        } else {
            let days = Int(hoursSinceLastLog / 24)
            return L.Time.daysAgo(days)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Что это значит
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L.Health.whatDoesItMean(currentPercentage))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(L.Health.explanation)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)

                        // Текущий статус
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.Health.lastCigarette)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textMuted)
                                Text(timeSinceText)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(L.Health.recovery)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textMuted)
                                Text("+\(currentPercentage)%")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Как это работает
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.Health.howItWorks)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            explanationRow(icon: "flame.fill", color: .orange,
                                text: L.Health.afterCigarette)
                            explanationRow(icon: "clock.fill", color: .blue,
                                text: L.Health.longerWithout)
                            explanationRow(icon: "star.fill", color: .green,
                                text: L.Health.threeDays)
                        }
                    }
                    .padding(16)
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(12)

                    Divider()

                    // Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L.Health.recoveryStages)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        ForEach(HealthMilestone.all, id: \.hours) { milestone in
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(hoursSinceLastLog >= milestone.hours ? Color.primaryAccent : Color.cardFill)
                                        .frame(width: 28, height: 28)

                                    if hoursSinceLastLog >= milestone.hours {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(milestone.timeLabel)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(hoursSinceLastLog >= milestone.hours ? .primaryAccent : .textPrimary)

                                    Text(milestone.benefit)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()

                                Text("+\(milestone.percentage)%")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(hoursSinceLastLog >= milestone.hours ? .primaryAccent : .textMuted)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Health.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }

    private func explanationRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
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

                        Text(L.Savings.savedToday)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    Divider()

                    // Calculation
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L.Savings.howCalculated)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            calculationRow(
                                label: L.Savings.usuallySmoke,
                                value: "\(baseline) \(L.Units.piecesPerDay)"
                            )

                            calculationRow(
                                label: L.Savings.todaySmoked,
                                value: "\(todayCount) \(L.Units.pieces)"
                            )

                            calculationRow(
                                label: L.Savings.saved,
                                value: "\(savedCount) \(L.Units.pieces)"
                            )

                            calculationRow(
                                label: L.Savings.pricePerUnit,
                                value: "\(String(format: "%.0f", pricePerUnit)) \(L.Units.tenge)"
                            )

                            Divider()

                            HStack {
                                Text(L.Savings.total)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("\(savedCount) × \(String(format: "%.0f", pricePerUnit)) = \(todaySavings) \(L.Units.tenge)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Note
                    Text(L.Savings.hint)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding(16)
                        .background(Color.primaryAccent.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Savings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
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
        case .veryRecent: return L.HealthStatus.veryRecentTitle
        case .recent: return L.HealthStatus.recentTitle
        case .recovering: return L.HealthStatus.recoveringTitle
        case .improving: return L.HealthStatus.improvingTitle
        case .strong: return L.HealthStatus.strongTitle
        case .excellent: return L.HealthStatus.excellentTitle
        }
    }

    var description: String {
        switch self {
        case .veryRecent:
            return L.HealthStatus.veryRecentDesc
        case .recent:
            return L.HealthStatus.recentDesc
        case .recovering:
            return L.HealthStatus.recoveringDesc
        case .improving:
            return L.HealthStatus.improvingDesc
        case .strong:
            return L.HealthStatus.strongDesc
        case .excellent:
            return L.HealthStatus.excellentDesc
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
    let timeLabelKey: () -> String
    let benefitKey: () -> String
    let percentage: Int

    var timeLabel: String { timeLabelKey() }
    var benefit: String { benefitKey() }

    static let all: [HealthMilestone] = [
        HealthMilestone(hours: 0.33, timeLabelKey: { L.Health.minutes20 }, benefitKey: { L.Health.benefit20min }, percentage: 5),
        HealthMilestone(hours: 2, timeLabelKey: { L.Health.hours2 }, benefitKey: { L.Health.benefit2h }, percentage: 25),
        HealthMilestone(hours: 8, timeLabelKey: { L.Health.hours8 }, benefitKey: { L.Health.benefit8h }, percentage: 40),
        HealthMilestone(hours: 24, timeLabelKey: { L.Health.hours24 }, benefitKey: { L.Health.benefit24h }, percentage: 70),
        HealthMilestone(hours: 48, timeLabelKey: { L.Health.hours48 }, benefitKey: { L.Health.benefit48h }, percentage: 85),
        HealthMilestone(hours: 72, timeLabelKey: { L.Health.hours72 }, benefitKey: { L.Health.benefit72h }, percentage: 95),
    ]
}

#Preview {
    HomeView()
}
