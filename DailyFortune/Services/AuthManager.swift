import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthManager: ObservableObject {
    
    @Published private(set) var isLoading = true
    @Published private(set) var token: String?
    @Published private(set) var currentUser: UserMeProfile?
    
    var isAuthenticated: Bool {
        return token != nil && currentUser != nil
    }
    
    init() {
        Task(priority: .userInitiated) {
            // --- FIX START: 重构整个初始化逻辑以实现持久化登录 ---
            
            // 1. 从 Keychain 读取存储的 token
            let storedToken = KeychainService.shared.getAccessToken()

            // 2. 如果存在 token，就尝试用它来获取用户信息
            if let token = storedToken, !token.isEmpty {
                self.token = token // 先设置 token
                await self.fetchCurrentUser() // 然后去服务器验证并获取用户信息
            }
            
            // 3. 无论登录成功与否（可能token已过期），都结束初始加载状态
            self.isLoading = false
            
            // --- FIX END ---
        }
    }
    
    func login(token: String, user: UserMeProfile) {
        KeychainService.shared.saveAccessToken(token: token)
        self.token = token
        self.currentUser = user
    }
    
    func logout() {
        KeychainService.shared.removeAccessToken()
        self.token = nil
        self.currentUser = nil
    }
    
    func fetchCurrentUser() async {
        guard token != nil else {
            // 如果在调用此方法时没有token，则确保是登出状态
            logout()
            return
        }
        
        do {
            let response = try await APIService.shared.getMyProfile()
            self.currentUser = response.user
        } catch {
            // 如果获取失败（例如token过期或网络错误），则登出
            print("持久化登录失败 (可能是token已过期): \(error.localizedDescription)")
            logout()
        }
    }
    
    func updateUser(_ newUser: UserMeProfile) {
        self.currentUser = newUser
    }
}
