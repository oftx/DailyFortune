import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // --- FIX: Corrected 'view' to 'View' ---
    var body: some View {
        if authManager.isLoading {
            VStack {
                ProgressView()
                Text("正在加载...")
                    .padding()
            }
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @StateObject private var myProfileViewModel = ProfileViewModel()
    
    // --- FIX: Corrected 'view' to 'View' ---
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
            
            if authManager.isAuthenticated {
                ProfileView(username: nil, viewModel: myProfileViewModel)
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                    }
            } else {
                LoginPromptView()
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                    }
            }
            
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
