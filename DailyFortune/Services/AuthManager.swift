import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthManager: ObservableObject {
    
    // --- FIX #1 START: 添加加载状态 ---
    @Published private(set) var isLoading = true
    // --- FIX #1 END ---
    
    @Published private(set) var token: String?
    @Published private(set) var currentUser: UserMeProfile?
    
    var isAuthenticated: Bool {
        return token != nil && currentUser != nil
    }
    
    init() {
        // 在后台任务中检查初始登录状态
        Task(priority: .userInitiated) {
            self.token = KeychainService.shared.getAccessToken()
            
            if self.isAuthenticated {
                await fetchCurrentUser()
            }
            
            // 无论成功与否，都结束加载状态
            self.isLoading = false
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
            logout()
            return
        }
        
        do {
            let response = try await APIService.shared.getMyProfile()
            self.currentUser = response.user
        } catch {
            print("获取用户信息失败: \(error.localizedDescription)")
            logout()
        }
    }
    
    func updateUser(_ newUser: UserMeProfile) {
        self.currentUser = newUser
    }
}
