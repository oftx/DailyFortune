import Foundation
import SwiftKeychainWrapper

/// 一个围绕 SwiftKeychainWrapper 的简单封装，用于提供类型安全的Token管理。
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let accessTokenKey = "dailyfortune.accessToken"

    /// 从Keychain中安全地保存访问令牌。
    /// - Parameter token: 要保存的JWT。
    /// - Returns: 如果保存成功则为true，否则为false。
    @discardableResult
    func saveAccessToken(token: String) -> Bool {
        return KeychainWrapper.standard.set(token, forKey: accessTokenKey)
    }

    /// 从Keychain中获取访问令牌。
    /// - Returns: 如果存在，则返回JWT；否则返回nil。
    func getAccessToken() -> String? {
        return KeychainWrapper.standard.string(forKey: accessTokenKey)
    }

    /// 从Keychain中移除访问令牌。
    /// - Returns: 如果移除成功则为true，否则为false。
    @discardableResult
    func removeAccessToken() -> Bool {
        return KeychainWrapper.standard.removeObject(forKey: accessTokenKey)
    }
}
