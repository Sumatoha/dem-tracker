import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showProgramExplanation = false
    @State private var showForecastExplanation = false

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
                        Text("Статистика — это компас вашего прогресса.\nКаждая цифра приближает вас к полной свободе.")
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
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Произошла ошибка")
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
            Text("Статистика")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - Hourly Activity Card

    private var hourlyActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("АКТИВНОСТЬ ПО ЧАСАМ")
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
            Text("САМЫЙ ЧАСТЫЙ\nТРИГГЕР")
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
                Text("Нет данных")
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
            Text("ЛУЧШИЙ\nРЕЗУЛЬТАТ")
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

                    Text("часов")
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }

                Text("БЕЗ СРЫВОВ")
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
            Text("ПРОГНОЗ ЭКОНОМИИ ЗА МЕСЯЦ")
                .font(.sectionLabel)
                .kerning(2)
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(viewModel.monthlyForecastSavings)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primaryAccent)

                Text("₸")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primaryAccent)
            }

            Text("При сохранении текущей динамики отказа от курения.")
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
                    Text("ПРОГРАММА")
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    Text("Неделя \(viewModel.currentWeekNumber) из \(viewModel.totalWeeksInProgram)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                // Current limit badge
                if let limit = viewModel.currentDailyLimit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Лимит")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                        Text("\(limit)/день")
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
                    Text("На этой неделе")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)

                    if total > 0 {
                        HStack(spacing: 4) {
                            Text("\(inPlan)/\(total)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(inPlan == total ? .green : .textPrimary)
                            Text("дней в плане")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Text("Нет данных")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Прогноз")
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
                Text("Старт")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textMuted)

                Spacer()

                Text("Цель")
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
                        Text("Что такое программа?")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text("Программа — это твой личный план постепенного снижения потребления сигарет. Вместо резкого отказа, ты плавно уменьшаешь количество день за днём.")
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }

                    // Как работает
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как это работает")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            if let start = startValue, let target = targetValue {
                                explanationRow(
                                    number: "1",
                                    title: "Стартовая точка",
                                    text: "Ты начал с \(start) сигарет в день"
                                )

                                explanationRow(
                                    number: "2",
                                    title: "Цель",
                                    text: target == 0 ? "Полный отказ от курения" : "Снизить до \(target) сигарет в день"
                                )

                                explanationRow(
                                    number: "3",
                                    title: "Срок",
                                    text: "За \(totalWeeks) недель (\(totalWeeks / 4) мес.)"
                                )
                            }

                            if let limit = currentLimit {
                                explanationRow(
                                    number: "4",
                                    title: "Сейчас",
                                    text: "Неделя \(currentWeek): лимит \(limit) сигарет/день"
                                )
                            }
                        }
                        .padding(16)
                        .background(Color.cardFill)
                        .cornerRadius(12)
                    }

                    // Что значит прогноз
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Что значит «Прогноз»?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Прогноз показывает, когда ты достигнешь цели, если будешь придерживаться плана. Он считается на основе твоего текущего прогресса.")
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
                        Text("Что значит «дней в плане»?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Это количество дней на этой неделе, когда ты не превысил свой дневной лимит. Чем больше дней в плане — тем лучше ты справляешься!")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Программа")
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
                        Text("Прогноз экономии")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text("Это сумма, которую ты сэкономишь за месяц, если будешь курить так же, как сейчас.")
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }

                    // Расчёт
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как считается")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        VStack(spacing: 12) {
                            calculationRow(
                                label: "Обычно куришь",
                                value: "\(baseline) шт/день"
                            )

                            calculationRow(
                                label: "Сейчас в среднем",
                                value: String(format: "%.1f шт/день", dailyAverage)
                            )

                            calculationRow(
                                label: "Экономишь в день",
                                value: String(format: "%.1f шт", savedPerDay)
                            )

                            calculationRow(
                                label: "Цена за штуку",
                                value: String(format: "%.0f ₸", pricePerUnit)
                            )

                            Divider()

                            HStack {
                                Text("За месяц (30 дней)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("\(monthlyForecast) ₸")
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

                        Text("Чем меньше куришь — тем больше экономишь. Каждая не выкуренная сигарета — это деньги в твоём кармане!")
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
            .navigationTitle("Прогноз")
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

#Preview {
    StatsView()
}
