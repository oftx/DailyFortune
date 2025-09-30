import Foundation

struct FortuneUtils {
    
    private enum FortuneType: String, CaseIterable {
        case sKichi = "諭吉"
        case daiKichi = "大吉"
        case kichi = "吉"
        case chuKichi = "中吉"
        case shoKichi = "小吉"
        case kyo = "凶"
        case daiKyo = "大凶"
    }
    
    /// 在本地模拟后端的两阶段概率模型来抽取运势。
    /// - Returns: 一个运势字符串。
    static func drawFortuneLocally() -> String {
        let goodFortunes: [FortuneType] = [.sKichi, .daiKichi, .kichi, .chuKichi, .shoKichi]
        let badFortunes: [FortuneType] = [.kyo, .daiKyo]
        
        // 第一阶段：80%概率进入“吉”池
        if Double.random(in: 0...1) <= 0.8 {
            // 第二阶段：在“吉”池中等概率随机选择
            return goodFortunes.randomElement()!.rawValue
        } else {
            // 第二阶段：在“凶”池中等概率随机选择
            return badFortunes.randomElement()!.rawValue
        }
    }
}
