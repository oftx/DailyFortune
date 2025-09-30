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

    // `fetchProfile` 方法保持不变
    func fetchProfile(username: String?, currentUser: UserMeProfile?) async {
        let isMyProfile = username == nil
        guard let usernameToFetch = isMyProfile ? currentUser?.username : username else {
            errorMessage = "未指定用户"
            isLoading = false
            return
        }
        
        if let currentProfile = self.displayableProfile, currentProfile.username == usernameToFetch {
            // Smooth refresh, no loading indicator
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

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
            // --- FIX #1 START: 移除重复的页面标题 ---
            .navigationBarTitleDisplayMode(.inline) // 可以保留，但标题内容为空
            .toolbar {
                // 将标题设置为空字符串，从而隐藏它但保留导航栏位置
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            // --- FIX #1 END ---
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

// --- FIX #2 & #3 START: 彻底重构 ProfileContentView ---
struct ProfileContentView: View {
    let profile: UserPublicProfile
    let history: [FortuneHistoryItem]
    let isMe: Bool
    
    private let headerHeight: CGFloat = 220

    var body: some View {
        ScrollView {
            // 使用 VStack 将头部和主体内容分开，避免重叠
            VStack(spacing: 0) {
                // 头部区域
                headerView
                    .frame(height: headerHeight)
                
                // 主体内容区域
                mainContentView
                    .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // 头部视图
    private var headerView: some View {
        ZStack {
            // 背景图层
            KFImage(URL(string: profile.backgroundUrl))
                .placeholder{
                    Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: headerHeight)
                .clipped()
            
            // 遮罩图层
            Rectangle()
                .fill(.black.opacity(0.4))
            
            // 用户信息内容图层
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 16) {
                    if let avatarUrl = profile.getDisplayAvatarUrl() {
                        KFImage(avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            // 修改为圆角矩形
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
                    
                    Spacer() // 将内容推向左侧
                }
                .padding()
            }
        }
    }
    
    // 主体内容视图
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

    // 统计数据子视图
    private func statItem(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 80) // 给每个项目一个最小宽度以优化布局
    }
}
// --- FIX #2 & #3 END ---
