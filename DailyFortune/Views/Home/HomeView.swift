import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var fortune: String?
    @Published var nextDrawAt: Date?
    @Published var countdown: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 警告来源: 这个 timer 属性被标记为 @MainActor-isolated
    private var timer: Timer?

    func checkUserStatus(user: UserMeProfile?, authManager: AuthManager) {
        guard let user = user else { return }
        if user.hasDrawnToday {
            self.fortune = user.todaysFortune
            // 刷新用户数据以获取倒计时
            Task {
                do {
                    let response = try await APIService.shared.getMyProfile()
                    self.nextDrawAt = response.nextDrawAt
                    self.startCountdown(authManager: authManager)
                } catch {
                    print("Failed to get nextDrawAt on load")
                }
            }
        } else {
            // 如果用户状态明确为“未抽取”，则重置视图
            self.fortune = nil
            self.nextDrawAt = nil
            self.countdown = ""
            timer?.invalidate()
        }
    }
    
    func startCountdown(authManager: AuthManager) {
        timer?.invalidate()
        guard let targetDate = nextDrawAt else { return }
        
        // Timer 的闭包是一个 @Sendable 闭包，它不能直接访问 MainActor 隔离的属性
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak authManager] _ in
            
            // --- 修复方案: 将所有逻辑包装在 Task { @MainActor in ... } 中 ---
            // 这可以确保闭包内的所有代码都在主线程上安全地执行，从而解决所有警告。
            Task { @MainActor in
                guard let self = self, let authManager = authManager else { return }
                
                let now = Date()
                let diff = targetDate.timeIntervalSince(now)

                if diff <= 0 {
                    self.timer?.invalidate()
                    self.fortune = nil
                    self.nextDrawAt = nil
                    self.countdown = ""
                    
                    // 这个 Task 继承了 @MainActor 上下文，所以是安全的
                    await authManager.fetchCurrentUser()
                    return
                }
                
                let hours = Int(diff) / 3600
                let minutes = Int(diff) / 60 % 60
                let seconds = Int(diff) % 60
                
                self.countdown = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
            }
        }
    }

    func drawFortune(authManager: AuthManager) {
        errorMessage = nil
        
        if authManager.isAuthenticated {
            isLoading = true
            Task {
                do {
                    let response = try await APIService.shared.drawFortune()
                    self.fortune = response.fortune
                    self.nextDrawAt = response.nextDrawAt
                    self.startCountdown(authManager: authManager)
                    await authManager.fetchCurrentUser()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        } else {
            self.fortune = FortuneUtils.drawFortuneLocally()
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            if let fortune = viewModel.fortune {
                Constants.FortuneColors.color(for: fortune)
                    .ignoresSafeArea()
                    .animation(.easeIn, value: fortune)
            } else {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                if let fortune = viewModel.fortune {
                    Text(authManager.isAuthenticated ? "你的今日运势是" : "今日运势是")
                        .font(.title2)
                    
                    Text(fortune)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                    
                    if authManager.isAuthenticated && !viewModel.countdown.isEmpty {
                        Text("距离下次抽取: \(viewModel.countdown)")
                            .font(.headline)
                    }
                } else {
                    Button(action: {
                        viewModel.drawFortune(authManager: authManager)
                    }) {
                        Text(viewModel.isLoading ? "抽取中..." : "抽取运势")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(.thickMaterial)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .foregroundColor(viewModel.fortune != nil ? .white : .primary)
            .shadow(radius: viewModel.fortune != nil ? 10 : 0)
        }
        .onAppear {
            viewModel.checkUserStatus(user: authManager.currentUser, authManager: authManager)
        }
        .onChange(of: authManager.currentUser) { newUser in
             viewModel.checkUserStatus(user: newUser, authManager: authManager)
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("好的") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
}
