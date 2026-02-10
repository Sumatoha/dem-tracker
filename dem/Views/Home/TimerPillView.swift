import SwiftUI

struct TimerPillView: View {
    let lastLogDate: Date?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            let elapsed = elapsedTime(from: lastLogDate, at: timeline.date)

            Text(elapsed)
                .font(.timerPill)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.primaryAccent)
                .cornerRadius(24)
        }
    }

    private func elapsedTime(from date: Date?, at now: Date) -> String {
        guard let date = date else {
            return "00:00:00"
        }

        let interval = max(0, now.timeIntervalSince(date))
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerPillView(lastLogDate: Date().addingTimeInterval(-8000))
        TimerPillView(lastLogDate: nil)
    }
    .padding()
    .background(Color.appBackground)
}
