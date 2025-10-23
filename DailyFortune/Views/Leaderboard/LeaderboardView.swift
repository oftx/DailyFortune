import SwiftUI
import Combine // <-- FIX: Added import

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardGroup] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    func fetchLeaderboard() {
        // 只有在首次加载、数据为空时，才将 isLoading 设为 true 以显示全屏加载器。
        // 对于下拉刷新，.refreshable 会提供自己的 UI，我们不应替换整个视图。
        if leaderboard.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        Task {
            do {
                self.leaderboard = try await APIService.shared.getLeaderboard()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            // 任务完成后，无论成功与否，都应将 isLoading 设为 false。
            isLoading = false
        }
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("加载失败")
                        Text(errorMessage).font(.caption).foregroundColor(.secondary)
                    }
                } else if viewModel.leaderboard.isEmpty {
                    Text("今天还没有人抽取运势。")
                } else {
                    List {
                        ForEach(viewModel.leaderboard) { group in
                            Section(header: Text(group.fortune).font(.headline)) {
                                ForEach(group.users) { user in
                                    NavigationLink(destination: ProfileView(username: user.username)) {
                                        Text(user.displayName)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("今日排行榜")
            .refreshable {
                // .refreshable 修饰符会处理刷新动画，我们只需调用获取数据的函数。
                viewModel.fetchLeaderboard()
            }
            .onAppear {
                // 仅在数据为空时才在 onAppear 中加载，避免切换标签时重复加载。
                if viewModel.leaderboard.isEmpty {
                    viewModel.fetchLeaderboard()
                }
            }
        }
    }
}
