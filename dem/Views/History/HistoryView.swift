import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Summary cards at top - compact
                        summaryCards

                        // Day groups
                        if viewModel.isLoading && viewModel.groupedLogs.isEmpty {
                            // Loading state
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text(L.Common.loading)
                                    .font(.bodyText)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if viewModel.groupedLogs.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "clock")
                                    .font(.system(size: 48))
                                    .foregroundColor(.textMuted.opacity(0.5))

                                Text(L.History.noData)
                                    .font(.bodyText)
                                    .foregroundColor(.textSecondary)

                                Text(L.History.noDataHint)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(viewModel.groupedLogs, id: \.date) { group in
                                VStack(spacing: 12) {
                                    // Day header
                                    HStack {
                                        Rectangle()
                                            .fill(Color.textMuted.opacity(0.4))
                                            .frame(height: 1)

                                        Text(viewModel.formatDate(group.date))
                                            .font(.system(size: 12, weight: .semibold))
                                            .kerning(2)
                                            .foregroundColor(.textSecondary)
                                            .fixedSize()
                                            .padding(.horizontal, 12)

                                        Rectangle()
                                            .fill(Color.textMuted.opacity(0.4))
                                            .frame(height: 1)
                                    }
                                    .padding(.vertical, 8)

                                    // Log entries
                                    ForEach(group.logs) { log in
                                        LogEntryCard(
                                            log: log,
                                            interval: viewModel.intervalSincePrevious(for: log, in: group.logs)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.bottom, 120)
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
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L.History.title)
                    .font(.screenTitle)
                    .foregroundColor(.textPrimary)

                Text(currentDateFormatted())
                    .font(.system(size: 13, weight: .medium))
                    .kerning(1)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func currentDateFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            CompactSummaryCard(
                title: currentMonthName(),
                value: "\(viewModel.monthlyCount)",
                style: .orange
            )

            CompactSummaryCard(
                title: L.History.cleanDays,
                value: "\(viewModel.cleanDays)",
                style: .dark
            )
        }
    }

    private func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: Date()).uppercased()
        return String(format: L.History.totalForMonth, monthName)
    }
}

// MARK: - Log Entry Card

struct LogEntryCard: View {
    let log: SmokingLog
    let interval: String?

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: log.createdAt)
    }

    private var triggerName: String {
        log.trigger?.displayName ?? L.Trigger.noTrigger
    }

    var body: some View {
        HStack(spacing: 16) {
            // Time circle
            ZStack {
                Circle()
                    .fill(Color.cardFill)
                    .frame(width: 56, height: 56)

                Text(formattedTime)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(log.trigger != nil ? .primaryAccent : .textPrimary)
            }

            // Trigger info
            VStack(alignment: .leading, spacing: 4) {
                Text(triggerName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)

                Text(L.History.trigger)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Interval
            if let interval = interval {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(interval)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryAccent)

                    Text(L.History.interval)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(1)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Compact Summary Card

struct CompactSummaryCard: View {
    let title: String
    let value: String
    let style: StatCard.CardStyleType

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1)
                    .foregroundColor(style.labelColor)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(style.textColor)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(style.backgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    HistoryView()
}
