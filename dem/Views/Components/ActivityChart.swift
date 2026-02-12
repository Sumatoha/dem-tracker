import SwiftUI
import Charts

struct ActivityChart: View {
    let data: [(day: String, count: Int)]
    let highlightLast: Bool
    let dailyLimit: Int?

    init(data: [(day: String, count: Int)], highlightLast: Bool = true, dailyLimit: Int? = nil) {
        self.data = data
        self.highlightLast = highlightLast
        self.dailyLimit = dailyLimit
    }

    private var maxCount: Int {
        let dataMax = data.map(\.count).max() ?? 1
        let limitMax = dailyLimit ?? 0
        return max(max(dataMax, limitMax), 1)
    }

    var body: some View {
        Chart {
            // Limit line (dashed gray) - only if program is active
            if let limit = dailyLimit {
                RuleMark(y: .value(L.Stats.limit, limit))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color(hex: "B5B1AA").opacity(0.7))
            }

            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.primaryAccent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                if highlightLast && index == data.count - 1 {
                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.primaryAccent)
                    .symbolSize(40)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.textMuted.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let day = value.as(String.self) {
                        let isLast = highlightLast && value.index == data.count - 1
                        Text(day)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isLast ? .primaryAccent : .textMuted)
                    }
                }
            }
        }
        .chartYScale(domain: 0...(Double(maxCount) * 1.2))
        .frame(height: 120)
    }
}

// MARK: - Hourly Activity Chart (for Stats)

struct HourlyActivityChart: View {
    let data: [(hour: Int, count: Int)]

    private var maxCount: Int {
        max(data.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.hour) { item in
                AreaMark(
                    x: .value("Hour", item.hour),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Hour", item.hour),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.primaryAccent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: [0, 8, 16, 24]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(String(format: "%02d:00", hour == 24 ? 23 : hour))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }
            }
        }
        .chartXScale(domain: 0...23)
        .chartYScale(domain: 0...(Double(maxCount) * 1.3))
        .frame(height: 140)
    }
}

#Preview {
    VStack(spacing: 32) {
        ActivityChart(data: [
            ("ПН", 8),
            ("ВТ", 12),
            ("СР", 6),
            ("ЧТ", 10),
            ("ПТ", 14),
            ("СБ", 11),
            ("ВС", 15)
        ])

        HourlyActivityChart(data: (0..<24).map { hour in
            let count: Int
            switch hour {
            case 8...10: count = Int.random(in: 5...10)
            case 12...14: count = Int.random(in: 8...15)
            case 18...20: count = Int.random(in: 10...20)
            default: count = Int.random(in: 0...5)
            }
            return (hour, count)
        })
    }
    .padding()
    .background(Color.appBackground)
}
