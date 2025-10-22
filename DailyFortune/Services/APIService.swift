import Foundation

// MARK: - APIError Enum
enum APIError: Error, LocalizedError {
    case invalidURL, requestFailed(Error), invalidResponse, httpError(statusCode: Int, message: String), decodingError(Error), unknownError
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL。"
        case .requestFailed(let error): return "网络请求失败: \(error.localizedDescription)"
        case .invalidResponse: return "收到无效的服务器响应。"
        case .httpError(_, let message): return message
        case .decodingError(let error): return "数据解析失败: \(error.localizedDescription)"
        case .unknownError: return "发生未知错误。"
        }
    }
}

// MARK: - APIService
final class APIService {
    static let shared = APIService()
    private init() {}
    private let baseURL = URL(string: "https://api.ys.oftx.top")!
    
    private static let iso8601Fractional: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"; f.calendar = Calendar(identifier: .iso8601); f.timeZone = TimeZone(secondsFromGMT: 0); f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()
    private static let iso8601: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"; f.calendar = Calendar(identifier: .iso8601); f.timeZone = TimeZone(secondsFromGMT: 0); f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer(); let s = try c.decode(String.self)
            if let date = APIService.iso8601Fractional.date(from: s) { return date }
            if let date = APIService.iso8601.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Date string does not match any expected ISO8601 format.")
        }
        return d
    }()

    private func request<T: Decodable>(endpoint: String, method: String = "GET", body: (any Encodable)? = nil, auth: Bool = true) async throws -> T {
        var r = URLRequest(url: baseURL.appendingPathComponent(endpoint)); r.httpMethod = method; r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = KeychainService.shared.getAccessToken() { r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { let e = JSONEncoder(); e.dateEncodingStrategy = .formatted(APIService.iso8601Fractional); r.httpBody = try e.encode(body) }
        let (data, response) = try await URLSession.shared.data(for: r)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail { throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail) }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "服务器错误，状态码: \(httpResponse.statusCode)")
        }
        do { return try decoder.decode(T.self, from: data) } catch { print("--- Decoding Error ---\n\(String(describing: error))\n----------------------"); throw APIError.decodingError(error) }
    }
    
    private func requestNoContent(endpoint: String, method: String = "POST", body: (any Encodable)? = nil, auth: Bool = true) async throws {
        var r = URLRequest(url: baseURL.appendingPathComponent(endpoint)); r.httpMethod = method; r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = KeychainService.shared.getAccessToken() { r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { let e = JSONEncoder(); e.dateEncodingStrategy = .formatted(APIService.iso8601Fractional); r.httpBody = try e.encode(body) }
        let (data, response) = try await URLSession.shared.data(for: r)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
             if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail { throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail) }
             _ = String(data: data, encoding: .utf8) ?? "No error message"
             throw APIError.httpError(statusCode: httpResponse.statusCode, message: "服务器错误")
        }
    }

    func getRegistrationStatus() async throws -> RegistrationStatusResponse { try await request(endpoint: "/config/registration-status", auth: false) }
    func login(username: String, password: String) async throws -> AuthResponse {
        var r = URLRequest(url: baseURL.appendingPathComponent("/auth/login")); r.httpMethod = "POST"; r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""; let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        r.httpBody = "username=\(encodedUsername)&password=\(encodedPassword)".data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: r)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail { throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail) }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "登录失败")
        }
        do { return try decoder.decode(AuthResponse.self, from: data) } catch { print("--- Login Decoding Error ---\n\(String(describing: error))\n--------------------------"); throw APIError.decodingError(error) }
    }
    func register(username: String, email: String, password: String) async throws -> AuthResponse { try await request(endpoint: "/auth/register", method: "POST", body: ["username": username, "email": email, "password": password], auth: false) }
    func getMyProfile() async throws -> MyProfileResponse { try await request(endpoint: "/users/me") }
    func getUserProfile(username: String) async throws -> UserPublicProfile { try await request(endpoint: "/users/u/\(username)") }
    func updateMyProfile(payload: UserUpdatePayload) async throws -> MyProfileResponse { try await request(endpoint: "/users/me", method: "PATCH", body: payload) }
    func changePassword(current: String, new: String) async throws { try await requestNoContent(endpoint: "/users/me/password", method: "PATCH", body: ["current_password": current, "new_password": new]) }
    func getUserFortuneHistory(username: String) async throws -> [FortuneHistoryItem] { try await request(endpoint: "/users/u/\(username)/fortune-history") }
    func drawFortune() async throws -> FortuneDrawResponse { try await request(endpoint: "/fortune/draw", method: "POST", auth: true) }
    func getLeaderboard() async throws -> [LeaderboardGroup] { try await request(endpoint: "/fortune/leaderboard") }
    func getAllUsers() async throws -> [UserMeProfile] { try await request(endpoint: "/admin/users") }
    func updateUserStatus(userId: String, status: String) async throws { try await requestNoContent(endpoint: "/admin/users/\(userId)/status", body: ["status": status]) }
    func updateUserVisibility(userId: String, isHidden: Bool) async throws { try await requestNoContent(endpoint: "/admin/users/\(userId)/visibility", body: ["is_hidden": isHidden]) }
    func updateUserTags(userId: String, tags: [String]) async throws { try await requestNoContent(endpoint: "/admin/users/\(userId)/tags", body: ["tags": tags]) }
}
