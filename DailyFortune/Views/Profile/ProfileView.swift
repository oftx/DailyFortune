import SwiftUI
import Kingfisher
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: (any Codable & Identifiable & Hashable)?
    
    @Published var history: [FortuneHistoryItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    var isMe: Bool { profile is UserMeProfile }
    
    var displayableProfile: UserPublicProfile? {
        if let p = profile as? UserMeProfile {
            return UserPublicProfile(username: p.username, displayName: p.displayName, bio: p.bio, avatarUrl: p.avatarUrl, backgroundUrl: p.backgroundUrl, registrationDate: p.registrationDate, lastActiveDate: p.lastActiveDate, totalDraws: p.totalDraws, hasDrawnToday: p.hasDrawnToday, todaysFortune: p.todaysFortune, status: p.status, isHidden: p.isHidden, tags: p.tags, qq: p.qq, useQqAvatar: p.useQqAvatar)
        }
        return profile as? UserPublicProfile
    }

    func fetchProfile(username: String?, currentUser: UserMeProfile?) async {
        let isMyProfile = username == nil
        guard let usernameToFetch = isMyProfile ? currentUser?.username : username else {
            errorMessage = "未指定用户"
            isLoading = false
            return
        }
        
        if let currentProfile = self.displayableProfile, currentProfile.username == usernameToFetch {
            // Smooth refresh
        } else {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            if isMyProfile {
                let response = try await APIService.shared.getMyProfile()
                self.profile = response.user
            } else {
                self.profile = try await APIService.shared.getUserProfile(username: usernameToFetch)
            }
            self.history = try await APIService.shared.getUserFortuneHistory(username: usernameToFetch)
        // --- FIX #2 START: 捕获并忽略 CancellationError ---
        } catch is CancellationError {
            // User cancelled the refresh action, do nothing.
            print("Refresh cancelled.")
        // --- FIX #2 END ---
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// ProfileView 和 ProfileContentView 结构体本身无需修改，保持原样即可
struct ProfileView: View {
    let username: String?
    
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("正在加载个人资料...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else if let profile = viewModel.displayableProfile {
                    ProfileContentView(profile: profile, history: viewModel.history, isMe: viewModel.isMe)
                } else {
                    Text("未能加载个人资料")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .refreshable {
                await viewModel.fetchProfile(username: username, currentUser: authManager.currentUser)
            }
            .onAppear {
                if username == nil, let currentUser = authManager.currentUser {
                    viewModel.profile = currentUser
                }
                Task {
                    await viewModel.fetchProfile(username: username, currentUser: authManager.currentUser)
                }
            }
        }
    }
}

struct ProfileContentView: View {
    let profile: UserPublicProfile
    let history: [FortuneHistoryItem]
    let isMe: Bool
    
    private let headerHeight: CGFloat = 220

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                    .frame(height: headerHeight)
                
                mainContentView
                    .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var headerView: some View {
        ZStack {
            KFImage(URL(string: profile.backgroundUrl))
                .placeholder{
                    Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: headerHeight)
                .clipped()
            
            Rectangle()
                .fill(.black.opacity(0.4))
            
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 16) {
                    if let avatarUrl = profile.getDisplayAvatarUrl() {
                        KFImage(avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white, lineWidth: 3)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("@\(profile.username)")
                            .font(.headline)
                            .opacity(0.8)
                    }
                    .foregroundColor(.white)
                    .shadow(radius: 3)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.body)
            }
            
            if profile.hasDrawnToday, let fortune = profile.todaysFortune {
                HStack {
                   Text(isMe ? "你的今日运势是" : "今日运势是")
                   Text(fortune).fontWeight(.bold).foregroundColor(Constants.FortuneColors.color(for: fortune))
                }
            } else if isMe {
                Text("今日运势尚未抽取。")
            }

            HStack(spacing: 0) {
                statItem(value: "\(profile.totalDraws)", label: "总抽取次数")
                Spacer()
                statItem(value: profile.registrationDate.toShortDateString(), label: "加入于")
                Spacer()
                statItem(value: profile.lastActiveDate.timeAgoDisplay(), label: "最近活跃")
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
            
            Text("运势历史 (近一年)")
                .font(.title2)
                .fontWeight(.bold)
            
            FortuneHeatmapView(history: history)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 80)
    }
}
