import SwiftUI
import Kingfisher
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    // --- FIX START ---
    // 修改 profile 类型，确保它始终是 UserMeProfile 或 UserPublicProfile
    @Published var profile: (any Codable & Identifiable)?
    // --- FIX END ---
    
    @Published var history: [FortuneHistoryItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    var isMe: Bool { profile is UserMeProfile }
    
    // --- FIX START ---
    // 统一将 profile 转换为 UserPublicProfile 以便视图使用，提供一致的接口
    var displayableProfile: UserPublicProfile? {
        if let p = profile as? UserMeProfile {
            return UserPublicProfile(username: p.username, displayName: p.displayName, bio: p.bio, avatarUrl: p.avatarUrl, backgroundUrl: p.backgroundUrl, registrationDate: p.registrationDate, lastActiveDate: p.lastActiveDate, totalDraws: p.totalDraws, hasDrawnToday: p.hasDrawnToday, todaysFortune: p.todaysFortune, status: p.status, isHidden: p.isHidden, tags: p.tags, qq: p.qq, useQqAvatar: p.useQqAvatar)
        }
        return profile as? UserPublicProfile
    }
    // --- FIX END ---

    func fetchProfile(username: String?, currentUser: UserMeProfile?) {
        let isMyProfile = username == nil
        guard let usernameToFetch = isMyProfile ? currentUser?.username : username else {
            errorMessage = "未指定用户"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isMyProfile {
                    // --- FIX START ---
                    // 调用返回 MyProfileResponse 的 getMyProfile
                    let response = try await APIService.shared.getMyProfile()
                    // 从响应中提取 user 对象
                    self.profile = response.user
                    // --- FIX END ---
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
            .navigationTitle(username == nil ? "我的资料" : (viewModel.displayableProfile?.displayName ?? "个人资料"))
            .refreshable {
                viewModel.fetchProfile(username: username, currentUser: authManager.currentUser)
            }
            .onAppear {
                // 如果是自己的资料页，并且本地已有数据，先显示
                if username == nil, let currentUser = authManager.currentUser {
                    viewModel.profile = currentUser
                }
                viewModel.fetchProfile(username: username, currentUser: authManager.currentUser)
            }
        }
    }
}


struct ProfileContentView: View {
    let profile: UserPublicProfile
    let history: [FortuneHistoryItem]
    let isMe: Bool

    var body: some View {
        ScrollView {
            VStack {
                // Header with background
                ZStack(alignment: .bottomLeading) {
                    KFImage(URL(string: profile.backgroundUrl))
                        .placeholder{
                            Rectangle().fill(.gray)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .overlay(.black.opacity(0.3))

                    HStack(alignment: .bottom) {
                        KFImage(URL(string: profile.avatarUrl))
                            .placeholder {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 5)
                        
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("@\(profile.username)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .shadow(radius: 3)
                        
                    }
                    .padding()
                }

                // Main content
                VStack(alignment: .leading, spacing: 20) {
                    // Bio
                    if !profile.bio.isEmpty {
                        Text(profile.bio)
                            .font(.body)
                    }
                    
                    // Today's Fortune
                    if profile.hasDrawnToday, let fortune = profile.todaysFortune {
                        HStack {
                           Text(isMe ? "你的今日运势是" : "今日运势是")
                           Text(fortune).fontWeight(.bold).foregroundColor(Constants.FortuneColors.color(for: fortune))
                        }
                    } else if isMe {
                        Text("今日运势尚未抽取。")
                    }

                    // Stats
                    HStack {
                        VStack {
                            Text("\(profile.totalDraws)")
                                .font(.headline)
                            Text("总抽取次数")
                                .font(.caption)
                        }
                        Spacer()
                        VStack {
                            Text(profile.registrationDate.toShortDateString())
                                .font(.headline)
                            Text("加入于")
                                .font(.caption)
                        }
                        Spacer()
                        VStack {
                            Text(profile.lastActiveDate.timeAgoDisplay())
                                .font(.headline)
                            Text("最近活跃")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(10)
                    
                    // History Heatmap
                    Text("运势历史 (近一年)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    FortuneHeatmapView(history: history)

                }.padding()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
