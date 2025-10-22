import SwiftUI
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardGroup] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    func fetchLeaderboard() async {
        if leaderboard.isEmpty { isLoading = true }
        errorMessage = nil
        do { self.leaderboard = try await APIService.shared.getLeaderboard() }
        catch { self.errorMessage = error.localizedDescription }
        isLoading = false
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading { ProgressView() }
                else if let errorMessage = viewModel.errorMessage { VStack { Text("加载失败"); Text(errorMessage).font(.caption).foregroundColor(.secondary) } }
                else if viewModel.leaderboard.isEmpty { Text("今天还没有人抽取运势。") }
                else {
                    List {
                        ForEach(viewModel.leaderboard) { group in
                            Section(header: Text(group.fortune).font(.headline)) {
                                ForEach(group.users) { user in
                                    NavigationLink(destination: ProfileView(username: user.username)) { Text(user.displayName) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("今日排行榜")
            .ifavailable_refreshable { await viewModel.fetchLeaderboard() }
            .onAppear { if viewModel.leaderboard.isEmpty { Task { await viewModel.fetchLeaderboard() } } }
        }
    }
}
