import SwiftUI

// MARK: - Colors

extension Color {
    static let appBackground = Color(hex: "F5F3EF")
    static let cardBackground = Color.white
    static let cardFill = Color(hex: "F0EDEA")
    static let primaryAccent = Color(hex: "E8612D")
    static let textPrimary = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "6B6965")
    static let textMuted = Color(hex: "8C8984")
    static let textLabel = Color(hex: "7A7672")
    static let success = Color(hex: "2D9F6F")
    static let buttonBlack = Color(hex: "1A1A1A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    static let giantCounter = Font.system(size: 96, weight: .bold, design: .default)
    static let timerPill = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let sectionLabel = Font.system(size: 12, weight: .semibold, design: .default)
    static let cardTitle = Font.system(size: 24, weight: .bold, design: .default)
    static let cardValue = Font.system(size: 18, weight: .bold, design: .default)
    static let bodyText = Font.system(size: 15, weight: .regular, design: .default)
    static let tabLabel = Font.system(size: 10, weight: .semibold, design: .default)
    static let buttonLabel = Font.system(size: 16, weight: .semibold, design: .default)
    static let screenTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let triggerLabel = Font.system(size: 13, weight: .bold, design: .default)
}

// MARK: - Layout Constants

enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let cardShadowRadius: CGFloat = 2
    static let cardShadowOpacity: CGFloat = 0.04
    static let bigButtonSize: CGFloat = 200
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

