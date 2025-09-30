import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isLoading {
            // 在检查持久化登录状态时显示加载视图
            VStack {
                ProgressView()
                Text("正在加载...")
                    .padding()
            }
        } else {
            // 加载完成后，始终显示主界面
            MainTabView()
        }
    }
}

// --- FIX START: 将 MainTabView 的定义移回此文件 ---
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
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
            
            // 根据登录状态决定显示个人资料还是登录提示
            if authManager.isAuthenticated {
                ProfileView(username: nil)
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                    }
            } else {
                LoginPromptView()
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                    }
            }
            
            // 根据登录状态决定显示设置还是登录提示
            if authManager.isAuthenticated {
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
            } else {
                LoginPromptView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
            }
        }
    }
}
// --- FIX END ---
