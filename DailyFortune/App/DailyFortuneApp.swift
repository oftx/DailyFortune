import SwiftUI
// --- 新增代码 1: 导入 WebP 解码器库 ---
import SDWebImageWebPCoder

@main
struct DailyFortuneApp: App {
    // 使用 @StateObject 在应用的生命周期内创建和维护 AuthManager 的实例
    @StateObject private var authManager = AuthManager()

    // --- 新增代码 2: 添加 init() 方法来注册解码器 ---
    init() {
        // 获取 SDWebImage 的全局解码器管理器
        let webPCoder = SDImageWebPCoder.shared
        // 将 WebP 解码器添加到管理器中
        // 这样 SDWebImage 在处理图片时，就会尝试使用这个解码器来解析 WebP 格式
        SDImageCodersManager.shared.addCoder(webPCoder)
    }

    var body: some Scene {
        WindowGroup {
            // 将 authManager作为环境对象注入到视图层级中
            ContentView()
                .environmentObject(authManager)
        }
    }
}
