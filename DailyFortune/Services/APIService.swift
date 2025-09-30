import Foundation

// MARK: - APIError Enum
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL。"
        case .requestFailed(let error):
            return "网络请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "收到无效的服务器响应。"
        case .httpError(_, let message):
            return message
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .unknownError:
            return "发生未知错误。"
        }
    }
}


// MARK: - APIService
final class APIService {
    static let shared = APIService()
    private init() {}

    // MARK: - Private Properties
    private let baseURL = URL(string: "https://api.ys.oftx.top")!
    
    // --- FINAL AND ROBUST FIX START ---
    // The API returns two slightly different ISO8601 date formats.
    // One with fractional seconds, and one without. We need a custom
    // decoder that can handle both gracefully.
    
    // Formatter for dates WITH fractional seconds (e.g., "2025-09-30T09:04:08.069000Z")
    private static let iso8601Fractional: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Formatter for dates WITHOUT fractional seconds (e.g., "2025-09-30T18:00:00Z")
    private static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Use a custom decoding strategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try parsing with the fractional seconds formatter first
            if let date = APIService.iso8601Fractional.date(from: dateString) {
                return date
            }
            // If that fails, try parsing with the non-fractional formatter
            if let date = APIService.iso8601.date(from: dateString) {
                return date
            }
            
            // If both fail, throw an error
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Date string does not match any expected ISO8601 format.")
        }
        return decoder
    }()
    // --- FINAL AND ROBUST FIX END ---

    // MARK: - Generic Request Function
    private func request<T: Decodable>(endpoint: String,
                                       method: String = "GET",
                                       body: (any Encodable)? = nil,
                                       auth: Bool = true) async throws -> T {
        
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            // When sending data to server, always use the standard with fractional seconds
            encoder.dateEncodingStrategy = .formatted(APIService.iso8601Fractional)
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail {
                 throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail)
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "服务器错误，状态码: \(httpResponse.statusCode)")
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("--- Decoding Error ---")
            print(String(describing: error))
            print("----------------------")
            throw APIError.decodingError(error)
        }
    }
    
    private func requestNoContent(endpoint: String,
                                  method: String = "POST",
                                  body: (any Encodable)? = nil,
                                  auth: Bool = true) async throws {
                                    
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(APIService.iso8601Fractional)
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
             let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail {
                 throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail)
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "服务器错误: \(errorMessage)")
        }
    }


    // MARK: - Auth Endpoints
    func getRegistrationStatus() async throws -> RegistrationStatusResponse {
        try await request(endpoint: "/config/registration-status", auth: false)
    }

    func login(username: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password)
        ]
        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail {
                 throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail)
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "登录失败")
        }
        
        do {
            return try decoder.decode(AuthResponse.self, from: data)
        } catch {
            print("--- Login Decoding Error ---")
            print(String(describing: error))
            print("--------------------------")
            throw APIError.decodingError(error)
        }
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body = ["username": username, "email": email, "password": password]
        return try await request(endpoint: "/auth/register", method: "POST", body: body, auth: false)
    }

    // MARK: - User Endpoints
    
    func getMyProfile() async throws -> MyProfileResponse {
        try await request(endpoint: "/users/me")
    }
    
    func getUserProfile(username: String) async throws -> UserPublicProfile {
        try await request(endpoint: "/users/u/\(username)")
    }

    func updateMyProfile(payload: UserUpdatePayload) async throws -> MyProfileResponse {
        try await request(endpoint: "/users/me", method: "PATCH", body: payload)
    }
    
    func changePassword(current: String, new: String) async throws {
        let body = ["current_password": current, "new_password": new]
        try await requestNoContent(endpoint: "/users/me/password", method: "PATCH", body: body)
    }
    
    func getUserFortuneHistory(username: String) async throws -> [FortuneHistoryItem] {
        try await request(endpoint: "/users/u/\(username)/fortune-history")
    }

    // MARK: - Fortune Endpoints
    func drawFortune() async throws -> FortuneDrawResponse {
        try await request(endpoint: "/fortune/draw", method: "POST", auth: true)
    }
    
    func getLeaderboard() async throws -> [LeaderboardGroup] {
        try await request(endpoint: "/fortune/leaderboard")
    }
    
    // MARK: - Admin Endpoints
    func getAllUsers() async throws -> [UserMeProfile] {
        try await request(endpoint: "/admin/users")
    }
    
    func updateUserStatus(userId: String, status: String) async throws {
        try await requestNoContent(endpoint: "/admin/users/\(userId)/status", body: ["status": status])
    }
    
    func updateUserVisibility(userId: String, isHidden: Bool) async throws {
        try await requestNoContent(endpoint: "/admin/users/\(userId)/visibility", body: ["is_hidden": isHidden])
    }
    
    func updateUserTags(userId: String, tags: [String]) async throws {
        try await requestNoContent(endpoint: "/admin/users/\(userId)/tags", body: ["tags": tags])
    }
}
