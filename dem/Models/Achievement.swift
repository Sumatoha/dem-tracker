import Foundation

struct Achievement: Codable, Identifiable {
    let id: Int64?
    let userId: UUID
    let badgeId: String
    let unlockedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case badgeId = "badge_id"
        case unlockedAt = "unlocked_at"
    }
}

enum Badge: String, CaseIterable {
    case firstDay = "first_day"
    case firstWeek = "first_week"
    case twoWeeks = "two_weeks"
    case oneMonth = "one_month"
    case halfReduction = "half_reduction"
    case resistedCraving = "resisted_craving"
    case tenResisted = "ten_resisted"
    case savedThousand = "saved_thousand"

    var displayName: String {
        switch self {
        case .firstDay: return "Первый день"
        case .firstWeek: return "Неделя"
        case .twoWeeks: return "Две недели"
        case .oneMonth: return "Месяц"
        case .halfReduction: return "Половина пути"
        case .resistedCraving: return "Устоял"
        case .tenResisted: return "10 побед"
        case .savedThousand: return "Экономист"
        }
    }

    var description: String {
        switch self {
        case .firstDay: return "Первый день отслеживания"
        case .firstWeek: return "Неделя использования приложения"
        case .twoWeeks: return "Две недели на пути к цели"
        case .oneMonth: return "Месяц контроля"
        case .halfReduction: return "Снизили потребление вдвое"
        case .resistedCraving: return "Первый раз устояли перед тягой"
        case .tenResisted: return "10 раз победили тягу"
        case .savedThousand: return "Сэкономили 1000₸"
        }
    }

    var iconName: String {
        switch self {
        case .firstDay: return "star.fill"
        case .firstWeek: return "calendar"
        case .twoWeeks: return "calendar.badge.checkmark"
        case .oneMonth: return "crown.fill"
        case .halfReduction: return "arrow.down.right"
        case .resistedCraving: return "hand.raised.fill"
        case .tenResisted: return "trophy.fill"
        case .savedThousand: return "tenge.circle.fill"
        }
    }
}
