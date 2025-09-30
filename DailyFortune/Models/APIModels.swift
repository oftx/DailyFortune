import Foundation

// MARK: - User Models

struct UserMeProfile: Codable, Identifiable {
    let id: String
    let email: String
    let role: String
    let language: String
    let timezone: String
    let username: String
    let displayName: String
    let bio: String
    let avatarUrl: String
    let backgroundUrl: String
    let registrationDate: Date
    let lastActiveDate: Date
    let totalDraws: Int
    let hasDrawnToday: Bool
    let todaysFortune: String?
    let status: String
    let isHidden: Bool
    let tags: [String]
    let qq: Int?
    let useQqAvatar: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, role, language, timezone, username, bio, tags, qq, status
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case backgroundUrl = "background_url"
        case registrationDate = "registration_date"
        case lastActiveDate = "last_active_date"
        case totalDraws = "total_draws"
        case hasDrawnToday = "has_drawn_today"
        case todaysFortune = "todays_fortune"
        case isHidden = "is_hidden"
        case useQqAvatar = "use_qq_avatar"
    }
}

struct UserPublicProfile: Codable, Identifiable {
    var id: String { username }
    let username: String
    let displayName: String
    let bio: String
    let avatarUrl: String
    let backgroundUrl: String
    let registrationDate: Date
    let lastActiveDate: Date
    let totalDraws: Int
    let hasDrawnToday: Bool
    let todaysFortune: String?
    let status: String
    let isHidden: Bool
    let tags: [String]
    let qq: Int?
    let useQqAvatar: Bool
    
    enum CodingKeys: String, CodingKey {
        case username, bio, tags, qq, status
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case backgroundUrl = "background_url"
        case registrationDate = "registration_date"
        case lastActiveDate = "last_active_date"
        case totalDraws = "total_draws"
        case hasDrawnToday = "has_drawn_today"
        case todaysFortune = "todays_fortune"
        case isHidden = "is_hidden"
        case useQqAvatar = "use_qq_avatar"
    }
}

// MARK: - Auth Models

// 用于 /auth/login, /auth/register 的响应模型
struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: UserMeProfile
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

// --- FIX START ---
// 新增：专门用于 /users/me 接口的响应模型
struct MyProfileResponse: Codable {
    let user: UserMeProfile
    let nextDrawAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case user
        case nextDrawAt = "next_draw_at"
    }
}
// --- FIX END ---

struct RegistrationStatusResponse: Codable {
    let isOpen: Bool
    enum CodingKeys: String, CodingKey {
        case isOpen = "is_open"
    }
}

// MARK: - Fortune Models

struct FortuneDrawResponse: Codable {
    let fortune: String
    let nextDrawAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case fortune
        case nextDrawAt = "next_draw_at"
    }
}

struct FortuneHistoryItem: Codable, Identifiable {
    var id: String { createdAt.ISO8601Format() }
    let createdAt: Date
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case value
    }
}


struct LeaderboardGroup: Codable, Identifiable {
    var id: String { fortune }
    let fortune: String
    let users: [LeaderboardUser]
}

struct LeaderboardUser: Codable, Identifiable {
    var id: String { username }
    let username: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
    }
}

// MARK: - API Error Model

struct APIErrorDetail: Codable {
    let loc: [String]
    let msg: String
    let type: String
}

struct APIErrorResponse: Codable {
    let detail: String?
}

// MARK: - Update Payloads

struct UserUpdatePayload: Codable {
    var displayName: String? = nil
    var bio: String? = nil
    var avatarUrl: String? = nil
    var backgroundUrl: String? = nil
    var language: String? = nil
    var timezone: String? = nil
    var qq: Int? = nil
    var useQqAvatar: Bool? = nil
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case backgroundUrl = "background_url"
        case language
        case timezone
        case qq
        case useQqAvatar = "use_qq_avatar"
    }
}
