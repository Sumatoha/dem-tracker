import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var onSettingsTapped: () -> Void = {}

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
            StatCard(
                title: "ЭКОНОМИЯ",
                value: "\(viewModel.todaySavings)",
                suffix: "₸",
                style: .light
            )

            StatCard(
                title: "ЗДОРОВЬЕ",
                value: "+\(viewModel.healthPercentage)%",
                icon: "arrow.up.right",
                style: .light
            )
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

#Preview {
    HomeView()
}
