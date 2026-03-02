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

        // Refresh at midnight to reset counter
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Entry

struct SmokingEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
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
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        Button(intent: LogSmokeIntent()) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                Text("\(entry.todayCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("сегодня")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left side - button
            Button(intent: LogSmokeIntent()) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .frame(width: 70, height: 70)

                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            // Right side - stats
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.todayCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)

                Text("сигарет сегодня")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
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
        .description("Быстро записывай сигареты одним тапом")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 5)
}

#Preview(as: .systemMedium) {
    demWidget()
} timeline: {
    SmokingEntry(date: .now, todayCount: 12)
}
