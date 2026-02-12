import Foundation

struct SmokingLog: Codable, Identifiable {
    let id: Int64?
    let userId: UUID
    let productType: ProductType?
    var trigger: TriggerType?
    var mood: String?
    var nicotineMg: Double?
    var price: Int?
    var note: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case productType = "product_type"
        case trigger
        case mood
        case nicotineMg = "nicotine_mg"
        case price
        case note
        case createdAt = "created_at"
    }

    // Safe accessor
    var safeProductType: ProductType { productType ?? .cigarette }
}

enum TriggerType: String, Codable, CaseIterable {
    case stress = "stress"
    case coffee = "coffee"
    case afterMeal = "after_meal"
    case alcohol = "alcohol"
    case boredom = "boredom"
    case social = "social"
    case beforeSleep = "before_sleep"
    case afterSleep = "after_sleep"

    var displayName: String {
        switch self {
        case .stress: return L.Trigger.stress
        case .coffee: return L.Trigger.coffee
        case .afterMeal: return L.Trigger.afterMeal
        case .alcohol: return L.Trigger.alcohol
        case .boredom: return L.Trigger.boredom
        case .social: return L.Trigger.social
        case .beforeSleep: return L.Trigger.beforeSleep
        case .afterSleep: return L.Trigger.afterSleep
        }
    }

    var iconName: String {
        switch self {
        case .stress: return "brain.head.profile"
        case .coffee: return "cup.and.saucer.fill"
        case .afterMeal: return "fork.knife"
        case .alcohol: return "wineglass.fill"
        case .boredom: return "face.dashed"
        case .social: return "person.2.fill"
        case .beforeSleep: return "moon.fill"
        case .afterSleep: return "sun.horizon.fill"
        }
    }
}

struct DailyStats: Codable {
    let date: Date
    let count: Int
    let totalPrice: Int
    let totalNicotine: Double

    enum CodingKeys: String, CodingKey {
        case date
        case count
        case totalPrice = "total_price"
        case totalNicotine = "total_nicotine"
    }
}
