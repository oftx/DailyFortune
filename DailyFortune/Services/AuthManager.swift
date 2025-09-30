import Foundation
import SwiftUI
import Combine // <-- FIX: Added import

/// 管理整个应用的认证状态的全局对象。
@MainActor
final class AuthManager: ObservableObject {
    
    /// 当前认证的JWT。
    @Published private(set) var token: String?
    
    /// 当前登录的用户信息。
    @Published private(set) var currentUser: UserMeProfile?
    
    /// 一个布尔值，指示用户是否已登录。
    var isAuthenticated: Bool {
        return token != nil && currentUser != nil
    }
    
    init() {
        self.token = KeychainService.shared.getAccessToken()
        // 如果启动时有token，则尝试获取用户信息
        if isAuthenticated {
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    /// 处理登录成功的逻辑。
    /// - Parameters:
    ///   - token: 从服务器获取的JWT。
    ///   - user: 从服务器获取的用户信息。
    func login(token: String, user: UserMeProfile) {
        KeychainService.shared.saveAccessToken(token: token)
        self.token = token
        self.currentUser = user
    }
    
    /// 处理登出逻辑。
    func logout() {
        KeychainService.shared.removeAccessToken()
        self.token = nil
        self.currentUser = nil
    }
    
    /// 从服务器获取或刷新当前用户信息。
    func fetchCurrentUser() async {
        guard token != nil else {
            // 如果没有token，则确保用户已登出
            logout()
            return
        }
        
        do {
            let response = try await APIService.shared.getMyProfile()
            self.currentUser = response.user
        } catch {
            // 如果获取失败（例如token过期），则登出
            print("获取用户信息失败: \(error.localizedDescription)")
            logout()
        }
    }
    
    /// 当用户信息被（例如在设置页）更新后，调用此方法来更新全局状态。
    func updateUser(_ newUser: UserMeProfile) {
        self.currentUser = newUser
    }
}
