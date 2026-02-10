import Foundation

struct Craving: Codable, Identifiable {
    let id: Int64?
    let userId: UUID
    var resisted: Bool
    var method: CravingMethod?
    var durationSeconds: Int?
    var trigger: String?
    var note: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case resisted
        case method
        case durationSeconds = "duration_seconds"
        case trigger
        case note
        case createdAt = "created_at"
    }
}

enum CravingMethod: String, Codable, CaseIterable {
    case breathing
    case willpower
    case distraction

    var displayName: String {
        switch self {
        case .breathing: return "Дыхательные упражнения"
        case .willpower: return "Сила воли"
        case .distraction: return "Отвлечение"
        }
    }

    var iconName: String {
        switch self {
        case .breathing: return "wind"
        case .willpower: return "bolt.fill"
        case .distraction: return "sparkles"
        }
    }
}
