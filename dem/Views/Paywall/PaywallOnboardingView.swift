import SwiftUI

struct PaywallOnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "hand.tap.fill",
                title: L.PaywallOnboarding.page1Title,
                subtitle: L.PaywallOnboarding.page1Subtitle,
                iconStyle: .accent
            ),
            OnboardingPage(
                icon: "chart.line.uptrend.xyaxis",
                title: L.PaywallOnboarding.page2Title,
                subtitle: L.PaywallOnboarding.page2Subtitle,
                iconStyle: .dark
            ),
            OnboardingPage(
                icon: "banknote.fill",
                title: L.PaywallOnboarding.page3Title,
                subtitle: L.PaywallOnboarding.page3Subtitle,
                iconStyle: .accent
            ),
            OnboardingPage(
                icon: "heart.fill",
                title: L.PaywallOnboarding.page4Title,
                subtitle: L.PaywallOnboarding.page4Subtitle,
                iconStyle: .dark
            )
        ]
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots at top
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.primaryAccent : Color.cardFill)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom section
                VStack(spacing: 16) {
                    // Continue button
                    Button {
                        Haptics.selection()
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? L.PaywallOnboarding.next : L.PaywallOnboarding.continueButton)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primaryAccent)
                            .cornerRadius(16)
                    }

                    // Skip button (except last page)
                    if currentPage < pages.count - 1 {
                        Button {
                            Haptics.selection()
                            onComplete()
                        } label: {
                            Text(L.PaywallOnboarding.skip)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon with background - app design style
            ZStack {
                Circle()
                    .fill(page.iconStyle.backgroundColor)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 8)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(page.iconStyle.iconColor)
            }

            Spacer()
                .frame(height: 48)

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Model

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let iconStyle: IconStyle

    enum IconStyle {
        case accent
        case dark

        var backgroundColor: Color {
            switch self {
            case .accent: return .primaryAccent
            case .dark: return .buttonBlack
            }
        }

        var iconColor: Color {
            .white
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallOnboardingView(onComplete: {})
}
