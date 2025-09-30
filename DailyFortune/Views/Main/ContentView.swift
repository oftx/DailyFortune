import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        // 根据认证状态显示不同的主视图
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
            
            LeaderboardView()
                .tabItem {
                    Label("排行榜", systemImage: "list.number")
                }

            ProfileView(username: nil) // 传入nil表示是自己的个人资料页
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}
