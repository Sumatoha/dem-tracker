import SwiftUI

struct PaywallOnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            title: "Отслеживай каждую сигарету",
            subtitle: "Простой трекинг в одно касание. Узнай, когда и почему ты куришь больше всего.",
            color: .blue
        ),
        OnboardingPage(
            icon: "banknote.fill",
            title: "Видь свою экономию",
            subtitle: "Посмотри, сколько денег ты сэкономишь, когда сократишь потребление.",
            color: .green
        ),
        OnboardingPage(
            icon: "heart.circle.fill",
            title: "Следи за здоровьем",
            subtitle: "Твоё тело восстанавливается каждую минуту без сигареты. Мы покажем прогресс.",
            color: .red
        ),
        OnboardingPage(
            icon: "target",
            title: "Персональная программа",
            subtitle: "Умный алгоритм поможет снизить потребление постепенно, без стресса.",
            color: .purple
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        Haptics.selection()
                        onComplete()
                    } label: {
                        Text("Пропустить")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.primaryAccent : Color.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Continue button
                Button {
                    Haptics.selection()
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryAccent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundColor(page.color)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

#Preview {
    PaywallOnboardingView(onComplete: {})
}
