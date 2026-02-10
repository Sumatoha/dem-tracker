import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

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
                            programCard
                        }

                        // Hourly Activity Card
                        hourlyActivityCard

                        // Trigger & Streak Cards
                        HStack(spacing: 12) {
                            triggerCard
                            streakCard
                        }

                        // Monthly Forecast Card
                        forecastCard

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

#Preview {
    StatsView()
}
