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
        case .decodingError:
            return "数据解析失败。"
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
    private let baseURL = URL(string: "https://api.ys.oftx.top")! // 重要：请替换为您的后端API地址
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

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
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            print("HTTP Error \(httpResponse.statusCode): \(errorMessage)")
            
            // 尝试解析标准的错误格式
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data), let detail = apiError.detail {
                 throw APIError.httpError(statusCode: httpResponse.statusCode, message: detail)
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "服务器错误，状态码: \(httpResponse.statusCode)")
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
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
        
        return try decoder.decode(AuthResponse.self, from: data)
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body = ["username": username, "email": email, "password": password]
        return try await request(endpoint: "/auth/register", method: "POST", body: body, auth: false)
    }

    // MARK: - User Endpoints
    
    // --- FIX START ---
    // 修改方法签名，使其返回新的、正确的模型
    func getMyProfile() async throws -> MyProfileResponse {
        try await request(endpoint: "/users/me")
    }
    // --- FIX END ---
    
    func getUserProfile(username: String) async throws -> UserPublicProfile {
        try await request(endpoint: "/users/u/\(username)")
    }

    // --- FIX START ---
    // 修改方法签名，使其返回 /users/me 接口正确的响应模型 MyProfileResponse
    func updateMyProfile(payload: UserUpdatePayload) async throws -> MyProfileResponse {
        try await request(endpoint: "/users/me", method: "PATCH", body: payload)
    }
    // --- FIX END ---
    
    func changePassword(current: String, new: String) async throws {
        let body = ["current_password": current, "new_password": new]
        try await requestNoContent(endpoint: "/users/me/password", method: "PATCH", body: body)
    }
    
    func getUserFortuneHistory(username: String) async throws -> [FortuneHistoryItem] {
        try await request(endpoint: "/users/u/\(username)/fortune-history")
    }

    // MARK: - Fortune Endpoints
    func drawFortune() async throws -> FortuneDrawResponse {
        try await request(endpoint: "/fortune/draw", method: "POST")
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
