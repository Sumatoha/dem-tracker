//
//  demWidget.swift
//  demWidget
//
//  Created by 1 on 02.03.2026.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SmokingEntry {
        SmokingEntry(date: Date(), todayCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmokingEntry) -> Void) {
        let entry = SmokingEntry(date: Date(), todayCount: SharedDataManager.shared.getTodayCount())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmokingEntry>) -> Void) {
        let currentDate = Date()
        let entry = SmokingEntry(date: currentDate, todayCount: SharedDataManager.shared.getTodayCount())

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct SmokingEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
}

// MARK: - Colors (matching app design)

struct WidgetColors {
    static let background = Color(red: 0.96, green: 0.95, blue: 0.94) // F5F3EF
    static let cardBackground = Color.white
    static let accent = Color(red: 0.91, green: 0.38, blue: 0.18) // E8612D
    static let buttonBlack = Color(red: 0.1, green: 0.1, blue: 0.1) // 1A1A1A
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let textSecondary = Color(red: 0.42, green: 0.41, blue: 0.40)
    static let textMuted = Color(red: 0.55, green: 0.54, blue: 0.52)
}

// MARK: - Widget View

struct demWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        case .accessoryCircular:
            accessoryCircularWidget
        case .accessoryRectangular:
            accessoryRectangularWidget
        case .accessoryInline:
            accessoryInlineWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Button(intent: LogSmokeIntent()) {
            ZStack {
                // Background
                WidgetColors.background

                VStack(spacing: 6) {
                    // Button circle
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(WidgetColors.accent.opacity(0.2), lineWidth: 2)
                            .frame(width: 50, height: 50)

                        // Inner button
                        Circle()
                            .fill(WidgetColors.buttonBlack)
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }

                    // Counter
                    Text("\(entry.todayCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(WidgetColors.textPrimary)
                        .minimumScaleFactor(0.8)

                    Text("СЕГОДНЯ")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(WidgetColors.textMuted)
                }
                .padding(.vertical, 12)
            }
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Button(intent: LogSmokeIntent()) {
            GeometryReader { geo in
                ZStack {
                    WidgetColors.background

                    HStack(spacing: 0) {
                        // Left side - Button
                        ZStack {
                            // Decorative ring
                            Circle()
                                .stroke(WidgetColors.accent.opacity(0.15), lineWidth: 4)
                                .frame(width: 88, height: 88)

                            Circle()
                                .fill(WidgetColors.buttonBlack)
                                .frame(width: 72, height: 72)
                                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: geo.size.width * 0.45)

                        // Right side - Stats
                        VStack(alignment: .leading, spacing: 4) {
                            Text("СЕГОДНЯ")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.5)
                                .foregroundColor(WidgetColors.textMuted)

                            Text("\(entry.todayCount)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(WidgetColors.textPrimary)

                            Text("сигарет")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(WidgetColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        Button(intent: LogSmokeIntent()) {
            GeometryReader { geo in
                ZStack {
                    WidgetColors.background

                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(WidgetColors.accent)
                                    .frame(width: 10, height: 10)
                                Text("dem")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(WidgetColors.textPrimary)
                            }
                            Spacer()
                            Text("СЕГОДНЯ")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.5)
                                .foregroundColor(WidgetColors.textMuted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        Spacer()

                        // Big button
                        ZStack {
                            // Outer decorative ring
                            Circle()
                                .stroke(WidgetColors.accent.opacity(0.12), lineWidth: 6)
                                .frame(width: 130, height: 130)

                            // Middle ring
                            Circle()
                                .stroke(WidgetColors.accent.opacity(0.08), lineWidth: 20)
                                .frame(width: 160, height: 160)

                            // Button
                            Circle()
                                .fill(WidgetColors.buttonBlack)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)

                            Image(systemName: "plus")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Spacer()
                            .frame(height: 24)

                        // Counter
                        Text("\(entry.todayCount)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(WidgetColors.textPrimary)

                        Text("сигарет")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(WidgetColors.textSecondary)

                        Spacer()

                        // Footer hint
                        Text("Нажми чтобы записать")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(WidgetColors.textMuted)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }

    // MARK: - Lock Screen Widgets

    private var accessoryCircularWidget: some View {
        Button(intent: LogSmokeIntent()) {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 1) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))

                    Text("\(entry.todayCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var accessoryRectangularWidget: some View {
        Button(intent: LogSmokeIntent()) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(entry.todayCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text("сигарет сегодня")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private var accessoryInlineWidget: some View {
        Button(intent: LogSmokeIntent()) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                Text("\(entry.todayCount) сигарет")
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Configuration

struct demWidget: Widget {
    let kind: String = "demWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            demWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("dem")
        .description("Записывай сигареты одним тапом")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 7)
}

#Preview(as: .systemMedium) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 12)
}

#Preview(as: .systemLarge) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 5)
}

#Preview(as: .accessoryCircular) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 3)
}

#Preview(as: .accessoryRectangular) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 8)
}
