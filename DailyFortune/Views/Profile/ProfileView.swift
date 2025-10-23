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

    private var currentUsername: String?
    
    func loadProfile(for username: String?, with currentUser: UserMeProfile?) async {
        let isMyProfile = username == nil
        guard let usernameToFetch = isMyProfile ? currentUser?.username : username else {
            errorMessage = "未指定用户"
            isLoading = false
            return
        }
        
        if self.profile == nil {
            self.isLoading = true
        }
        self.errorMessage = nil
        
        defer {
            if self.isLoading {
                self.isLoading = false
            }
        }
        
        do {
            async let profileData = fetchProfileData(username: usernameToFetch, isMe: isMyProfile)
            async let historyData = APIService.shared.getUserFortuneHistory(username: usernameToFetch)
            
            self.profile = try await profileData
            self.history = try await historyData
            
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func fetchProfileData(username: String, isMe: Bool) async throws -> (any Codable & Identifiable & Hashable) {
        if isMe {
            let response = try await APIService.shared.getMyProfile()
            return response.user
        } else {
            return try await APIService.shared.getUserProfile(username: username)
        }
    }
}

struct ProfileView: View {
    let username: String?
    
    @StateObject private var defaultViewModel = ProfileViewModel()
    @ObservedObject var viewModel: ProfileViewModel
    
    @EnvironmentObject var authManager: AuthManager

    init(username: String?, viewModel: ProfileViewModel) {
        self.username = username
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    init(username: String?) {
        let vm = ProfileViewModel()
        self.init(username: username, viewModel: vm)
        _defaultViewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) { Text("") }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await viewModel.loadProfile(for: username, with: authManager.currentUser)
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                // --- FIX START: Replace .task with .onAppear for iOS 14 ---
                .onAppear {
                    Task {
                        await viewModel.loadProfile(for: username, with: authManager.currentUser)
                    }
                }
                // --- FIX END ---
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("正在加载个人资料...")
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                Text("加载失败")
                    .font(.headline)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        } else if let profile = viewModel.displayableProfile {
            ProfileContentView(profile: profile, history: viewModel.history, isMe: viewModel.isMe)
        } else {
            Text("未能加载个人资料，请重试。")
                .foregroundColor(.secondary)
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
        .edgesIgnoringSafeArea(.top)
    }
    
    private var headerView: some View {
        ZStack {
            KFImage(URL(string: profile.backgroundUrl))
                .placeholder{
                    Rectangle().fill(Color(.systemBackground))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: headerHeight)
                .clipped()
            
            if !profile.backgroundUrl.isEmpty {
                Rectangle()
                    .fill(.black.opacity(0.4))
            }
            
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 16) {
                    if let avatarUrl = profile.getDisplayAvatarUrl() {
                        KFImage(avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            // --- FIX START: Replace iOS 15+ overlay modifier ---
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            // --- FIX END ---
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("@\(profile.username)")
                            .font(.headline)
                            .opacity(0.8)
                    }
                    .foregroundColor(profile.backgroundUrl.isEmpty ? .primary : .white)
                    .shadow(radius: profile.backgroundUrl.isEmpty ? 0 : 3)
                    
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
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
