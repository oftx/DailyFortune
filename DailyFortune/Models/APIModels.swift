import Foundation

// MARK: - User Models

struct UserMeProfile: Codable, Identifiable, Hashable, Equatable {
    let id: String, email: String, role: String, language: String, timezone: String, username: String, displayName: String, bio: String, avatarUrl: String, backgroundUrl: String
    let registrationDate: Date, lastActiveDate: Date
    let totalDraws: Int, hasDrawnToday: Bool
    let todaysFortune: String?, status: String
    let isHidden: Bool
    let tags: [String]
    let qq: Int?, useQqAvatar: Bool
    enum CodingKeys: String, CodingKey {
        case id, email, role, language, timezone, username, bio, tags, qq, status
        case displayName = "display_name", avatarUrl = "avatar_url", backgroundUrl = "background_url", registrationDate = "registration_date", lastActiveDate = "last_active_date", totalDraws = "total_draws", hasDrawnToday = "has_drawn_today", todaysFortune = "todays_fortune", isHidden = "is_hidden", useQqAvatar = "use_qq_avatar"
    }
    func getDisplayAvatarUrl() -> URL? {
        if useQqAvatar, let qqNumber = qq { return URL(string: "https://q.qlogo.cn/g?b=qq&nk=\(qqNumber)&s=640") }
        if !avatarUrl.isEmpty { return URL(string: avatarUrl) }
        return nil
    }
}

struct UserPublicProfile: Codable, Identifiable, Hashable, Equatable {
    var id: String { username }
    let username: String, displayName: String, bio: String, avatarUrl: String, backgroundUrl: String
    let registrationDate: Date, lastActiveDate: Date
    let totalDraws: Int, hasDrawnToday: Bool
    let todaysFortune: String?, status: String
    let isHidden: Bool
    let tags: [String]
    let qq: Int?, useQqAvatar: Bool
    enum CodingKeys: String, CodingKey {
        case username, bio, tags, qq, status
        case displayName = "display_name", avatarUrl = "avatar_url", backgroundUrl = "background_url", registrationDate = "registration_date", lastActiveDate = "last_active_date", totalDraws = "total_draws", hasDrawnToday = "has_drawn_today", todaysFortune = "todays_fortune", isHidden = "is_hidden", useQqAvatar = "use_qq_avatar"
    }
    func getDisplayAvatarUrl() -> URL? {
        if useQqAvatar, let qqNumber = qq { return URL(string: "https://q.qlogo.cn/g?b=qq&nk=\(qqNumber)&s=640") }
        if !avatarUrl.isEmpty { return URL(string: avatarUrl) }
        return nil
    }
}

// MARK: - Auth Models
struct AuthResponse: Codable {
    let accessToken: String, tokenType: String, user: UserMeProfile
    enum CodingKeys: String, CodingKey { case accessToken = "access_token", tokenType = "token_type", user }
}
struct MyProfileResponse: Codable {
    let user: UserMeProfile, nextDrawAt: Date?
    enum CodingKeys: String, CodingKey { case user, nextDrawAt = "next_draw_at" }
}
struct RegistrationStatusResponse: Codable {
    let isOpen: Bool
    enum CodingKeys: String, CodingKey { case isOpen = "is_open" }
}
// MARK: - Fortune Models
struct FortuneDrawResponse: Codable {
    let fortune: String, nextDrawAt: Date?
    enum CodingKeys: String, CodingKey { case fortune, nextDrawAt = "next_draw_at" }
}
struct FortuneHistoryItem: Codable, Identifiable {
    var id: String { createdAt.toISO8601String() }
    let createdAt: Date, value: String
    enum CodingKeys: String, CodingKey { case createdAt = "created_at", value }
}
struct LeaderboardGroup: Codable, Identifiable {
    var id: String { fortune }
    let fortune: String, users: [LeaderboardUser]
}
struct LeaderboardUser: Codable, Identifiable {
    var id: String { username }
    let username: String, displayName: String
    enum CodingKeys: String, CodingKey { case username, displayName = "display_name" }
}
// MARK: - API Error Model
struct APIErrorDetail: Codable { let loc: [String], msg: String, type: String }
struct APIErrorResponse: Codable { let detail: String? }
// MARK: - Update Payloads
struct UserUpdatePayload: Codable {
    var displayName: String? = nil, bio: String? = nil, avatarUrl: String? = nil, backgroundUrl: String? = nil, language: String? = nil, timezone: String? = nil, qq: Int? = nil, useQqAvatar: Bool? = nil
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name", bio, avatarUrl = "avatar_url", backgroundUrl = "background_url", language, timezone, qq, useQqAvatar = "use_qq_avatar"
    }
}
