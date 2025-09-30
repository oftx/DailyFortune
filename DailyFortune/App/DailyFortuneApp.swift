import SwiftUI

@main
struct DailyFortuneApp: App {
    // 使用 @StateObject 在应用的生命周期内创建和维护 AuthManager 的实例
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            // 将 authManager作为环境对象注入到视图层级中
            ContentView()
                .environmentObject(authManager)
        }
    }
}
