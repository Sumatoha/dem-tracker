import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home
        case history
        case stats
        case profile

        var title: String {
            switch self {
            case .home: return L.Tab.home
            case .history: return L.Tab.history
            case .stats: return L.Tab.stats
            case .profile: return L.Tab.profile
            }
        }

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .history: return "clock.fill"
            case .stats: return "chart.bar.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content - no animation on tab switch for smoother feel
            Group {
                switch selectedTab {
                case .home:
                    HomeView(onSettingsTapped: { selectedTab = .profile })
                case .history:
                    HistoryView()
                case .stats:
                    StatsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    Haptics.selection()
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .primaryAccent : .textMuted)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .primaryAccent : .textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    MainTabView()
}
