import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var fortune: String?
    @Published var nextDrawAt: Date?
    @Published var countdown: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var timer: Timer?

    func checkUserStatus(user: UserMeProfile?) {
        guard let user = user else { return }
        if user.hasDrawnToday {
            self.fortune = user.todaysFortune
            // 刷新用户数据以获取倒计时
            Task {
                do {
                    let response = try await APIService.shared.getMyProfile()
                    self.nextDrawAt = response.nextDrawAt
                    self.startCountdown()
                } catch {
                    print("Failed to get nextDrawAt on load")
                }
            }
        }
    }
    
    func startCountdown() {
        timer?.invalidate()
        guard let targetDate = nextDrawAt else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let now = Date()
            let diff = targetDate.timeIntervalSince(now)

            if diff <= 0 {
                self?.countdown = "00:00:00"
                self?.timer?.invalidate()
                self?.fortune = nil
                self?.nextDrawAt = nil
                return
            }
            
            let hours = Int(diff) / 3600
            let minutes = Int(diff) / 60 % 60
            let seconds = Int(diff) % 60
            
            self?.countdown = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        }
    }

    func drawFortune(authManager: AuthManager) {
        errorMessage = nil
        
        if authManager.isAuthenticated {
            // 已登录用户，调用API
            isLoading = true
            Task {
                do {
                    let response = try await APIService.shared.drawFortune()
                    self.fortune = response.fortune
                    self.nextDrawAt = response.nextDrawAt
                    self.startCountdown()
                    await authManager.fetchCurrentUser()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        } else {
            // 未登录用户，本地计算
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
                        // --- FIX START: 优化倒计时元素背景以提高对比度 ---
                        Text("距离下次抽取: \(viewModel.countdown)")
                            .font(.headline)
                            .padding()
                            // 使用半透明黑色背景，确保在任何彩色背景上都有足够对比度
                            .background(Color.black.opacity(0.25))
                            .cornerRadius(10)
                        // --- FIX END ---
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
            viewModel.checkUserStatus(user: authManager.currentUser)
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("好的") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
}
