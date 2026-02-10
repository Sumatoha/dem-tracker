import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let suffix: String?
    let icon: String?
    let style: CardStyleType

    init(
        title: String,
        value: String,
        suffix: String? = nil,
        icon: String? = nil,
        style: CardStyleType = .light
    ) {
        self.title = title
        self.value = value
        self.suffix = suffix
        self.icon = icon
        self.style = style
    }

    enum CardStyleType {
        case light
        case orange
        case dark

        var backgroundColor: Color {
            switch self {
            case .light: return .cardFill
            case .orange: return .primaryAccent
            case .dark: return .buttonBlack
            }
        }

        var textColor: Color {
            switch self {
            case .light: return .textPrimary
            case .orange, .dark: return .white
            }
        }

        var labelColor: Color {
            switch self {
            case .light: return .textMuted
            case .orange, .dark: return .white.opacity(0.8)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.sectionLabel)
                .kerning(1)
                .foregroundColor(style.labelColor)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.cardTitle)
                    .foregroundColor(style.textColor)

                if let suffix = suffix {
                    Text(suffix)
                        .font(.cardValue)
                        .foregroundColor(style.textColor)
                }

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(style == .light ? .primaryAccent : style.textColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(style.backgroundColor)
        .cornerRadius(Layout.cardCornerRadius)
    }
}

// MARK: - Summary Card (for bottom of History)

struct SummaryCard: View {
    let title: String
    let value: String
    let style: StatCard.CardStyleType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.sectionLabel)
                .kerning(1)
                .foregroundColor(style.labelColor)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(style.textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(style.backgroundColor)
        .cornerRadius(Layout.cardCornerRadius)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            StatCard(title: "ЭКОНОМИЯ", value: "450", suffix: "₽", style: .light)
            StatCard(title: "ЗДОРОВЬЕ", value: "+12%", icon: "arrow.up.right", style: .light)
        }

        HStack(spacing: 12) {
            SummaryCard(title: "ВСЕГО ЗА МАЙ", value: "342", style: .orange)
            SummaryCard(title: "ЧИСТЫХ ДНЕЙ", value: "0", style: .dark)
        }
    }
    .padding()
    .background(Color.appBackground)
}
