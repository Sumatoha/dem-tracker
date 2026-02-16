import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showProgramExplanation = false
    @State private var showForecastExplanation = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Program Card (only if program is active)
                        if viewModel.hasProgramActive {
                            Button {
                                Haptics.selection()
                                showProgramExplanation = true
                            } label: {
                                programCard
                            }
                            .buttonStyle(.plain)
                        }

                        // Hourly Activity Card
                        hourlyActivityCard

                        // Trigger & Streak Cards
                        HStack(spacing: 12) {
                            triggerCard
                            streakCard
                        }

                        // Monthly Forecast Card
                        Button {
                            Haptics.selection()
                            showForecastExplanation = true
                        } label: {
                            forecastCard
                        }
                        .buttonStyle(.plain)

                        // Motivational text
                        Text(L.Stats.motivationalText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .padding(.bottom, 120)
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                }
                .refreshable {
                    await viewModel.loadData()
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .alert(L.Common.error, isPresented: $viewModel.showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? L.Common.error)
        }
        .sheet(isPresented: $showProgramExplanation) {
            ProgramExplanationView(
                currentWeek: viewModel.currentWeekNumber,
                totalWeeks: viewModel.totalWeeksInProgram,
                currentLimit: viewModel.currentDailyLimit,
                startValue: viewModel.programStartValue,
                targetValue: viewModel.programTargetValue,
                projectionText: viewModel.projectionText
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showForecastExplanation) {
            ForecastExplanationView(
                monthlyForecast: viewModel.monthlyForecastSavings,
                dailyAverage: viewModel.dailyAverageSavings,
                baseline: viewModel.baseline,
                pricePerUnit: viewModel.pricePerUnit
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text(L.Stats.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)

            Spacer()

            Button {
                Haptics.selection()
                shareProgress()
            } label: {
                Text(L.Stats.share)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primaryAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - Share

    private func shareProgress() {
        let stats = ShareManager.calculateStats(logs: viewModel.logs)
        ShareManager.shareProgress(stats: stats)
    }

    // MARK: - Hourly Activity Card

    private var hourlyActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.Stats.hourlyActivity)
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    Text(viewModel.peakHours)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryAccent.opacity(0.5))
            }

            HourlyActivityChart(data: viewModel.hourlyDistribution)
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Trigger Card

    private var triggerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.Stats.mostFrequentTrigger)
                .font(.sectionLabel)
                .kerning(1)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let triggerData = viewModel.mostFrequentTrigger {
                VStack(alignment: .leading, spacing: 4) {
                    Text(triggerData.trigger.displayName)
                        .font(.cardTitle)
                        .foregroundColor(.textPrimary)

                    Text("\(triggerData.percentage)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryAccent)
                }
            } else {
                Text(L.Stats.noData)
                    .font(.cardValue)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.Stats.longestStreak)
                .font(.sectionLabel)
                .kerning(1)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.longestStreak)")
                        .font(.cardTitle)
                        .foregroundColor(.textPrimary)

                    Text(L.Stats.hours)
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }

                Text(L.Stats.withoutBreaks)
                    .font(.sectionLabel)
                    .kerning(1)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Forecast Card

    private var forecastCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.Stats.monthlyForecast)
                .font(.sectionLabel)
                .kerning(2)
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(viewModel.monthlyForecastSavings)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primaryAccent)

                Text(L.Units.tenge)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primaryAccent)
            }

            Text(L.Stats.ifMaintainDynamics)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            // Progress indicator
            HStack {
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.primaryAccent.opacity(0.15))
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Program Card

    private var programCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.Stats.program)
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    Text(L.Stats.weekOfTotal(viewModel.currentWeekNumber, viewModel.totalWeeksInProgram))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                // Current limit badge
                if let limit = viewModel.currentDailyLimit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L.Stats.limit)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                        Text(L.Stats.limitPerDay(limit))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryAccent)
                    }
                }
            }

            // Simple progress visualization
            ProgramProgressView(
                currentWeek: viewModel.currentWeekNumber,
                totalWeeks: viewModel.totalWeeksInProgram,
                daysInPlan: viewModel.daysInPlanThisWeek
            )

            // Stats below
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    let (inPlan, total) = viewModel.daysInPlanThisWeek
                    Text(L.Stats.thisWeekLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)

                    if total > 0 {
                        HStack(spacing: 4) {
                            Text("\(inPlan)/\(total)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(inPlan == total ? .green : .textPrimary)
                            Text(L.Stats.daysInPlan)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text(L.Stats.noData)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L.Stats.forecast)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Text(viewModel.projectionText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primaryAccent)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Program Progress View (simpler visualization)

struct ProgramProgressView: View {
    let currentWeek: Int
    let totalWeeks: Int
    let daysInPlan: (inPlan: Int, total: Int)

    var progressPercent: Double {
        Double(currentWeek) / Double(totalWeeks)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Week progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.cardFill)
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryAccent.opacity(0.7), Color.primaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercent, height: 12)
                }
            }
            .frame(height: 12)

            // Week markers
            HStack {
                Text(L.Stats.startMarker)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textMuted)

                Spacer()

                Text(L.Stats.goalMarker)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textMuted)
            }
        }
    }
}

// MARK: - Program Explanation View

struct ProgramExplanationView: View {
    let currentWeek: Int
    let totalWeeks: Int
    let currentLimit: Int?
    let startValue: Int?
    let targetValue: Int?
    let projectionText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Что это
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.Program.whatIsProgram)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(L.Program.programExplanation)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }

                    // Как работает
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L.Program.howItWorks)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            if let start = startValue, let target = targetValue {
                                explanationRow(
                                    number: "1",
                                    title: L.Program.startingPoint,
                                    text: String(format: L.Program.startedWith, start)
                                )

                                explanationRow(
                                    number: "2",
                                    title: L.Program.goal,
                                    text: target == 0 ? L.Program.fullQuit : String(format: L.Program.reduceTo, target)
                                )

                                explanationRow(
                                    number: "3",
                                    title: L.Program.timeline,
                                    text: String(format: L.Program.weeksFormat, totalWeeks, totalWeeks / 4)
                                )
                            }

                            if let limit = currentLimit {
                                explanationRow(
                                    number: "4",
                                    title: L.Program.current,
                                    text: String(format: L.Program.weekLimit, currentWeek, limit)
                                )
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Что значит прогноз
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.Program.whatIsForecast)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text(L.Program.forecastExplanation)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)

                        HStack {
                            Image(systemName: "target")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryAccent)

                            Text(projectionText)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primaryAccent)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primaryAccent.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Что значит дни в плане
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.Program.whatIsDaysInPlan)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text(L.Program.daysInPlanExplanation)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Program.title)
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

    private func explanationRow(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.primaryAccent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Forecast Explanation View

struct ForecastExplanationView: View {
    let monthlyForecast: Int
    let dailyAverage: Double
    let baseline: Int
    let pricePerUnit: Double

    @Environment(\.dismiss) private var dismiss

    var savedPerDay: Double {
        max(0, Double(baseline) - dailyAverage)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Что это
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.Forecast.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text(L.Forecast.explanation)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }

                    // Расчёт
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L.Savings.howCalculated)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(spacing: 12) {
                            calculationRow(
                                label: L.Savings.usuallySmoke,
                                value: "\(baseline) \(L.Units.piecesPerDay)"
                            )

                            calculationRow(
                                label: L.Forecast.currentAverage,
                                value: String(format: "%.1f \(L.Units.piecesPerDay)", dailyAverage)
                            )

                            calculationRow(
                                label: L.Forecast.savePerDay,
                                value: String(format: "%.1f \(L.Units.pieces)", savedPerDay)
                            )

                            calculationRow(
                                label: L.Savings.pricePerUnit,
                                value: String(format: "%.0f \(L.Units.tenge)", pricePerUnit)
                            )

                            Divider()

                            HStack {
                                Text(L.Forecast.perMonth)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("\(monthlyForecast) \(L.Units.tenge)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Подсказка
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)

                        Text(L.Forecast.hint)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(16)
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Stats.forecast)
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

#Preview {
    StatsView()
}
