import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRegistrationOpen = true

    func checkRegistrationStatus() {
        Task {
            do {
                let response = try await APIService.shared.getRegistrationStatus()
                self.isRegistrationOpen = response.isOpen
            } catch {
                self.isRegistrationOpen = true
            }
        }
    }
    
    func login(authManager: AuthManager, completion: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.login(username: username, password: password)
                authManager.login(token: response.accessToken, user: response.user)
                completion()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    // --- FIX START: 监测颜色模式 ---
    @Environment(\.colorScheme) var colorScheme
    // --- FIX END ---

    var body: some View {
        NavigationStack {
            // --- FIX START: 使用 ZStack 来控制背景颜色 ---
            ZStack {
                // 在亮色模式下，设置背景为系统分组灰色
                if colorScheme == .light {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                // 主内容
                VStack {
                    Text("每日运势")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 40)

                    Form {
                        Section {
                            TextField("用户名", text: $viewModel.username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                            SecureField("密码", text: $viewModel.password)
                                .textContentType(.password)
                        }
                    }
                    .frame(height: 150)
                    .scrollDisabled(true)
                    // 隐藏 Form 的默认背景，以显示 ZStack 中的自定义背景
                    .scrollContentBackground(.hidden)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Button(action: {
                        viewModel.login(authManager: authManager) {
                            dismiss()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("登录")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    .padding()

                    HStack {
                        Text("没有账户？")
                        if viewModel.isRegistrationOpen {
                            NavigationLink("点此注册", destination: RegisterView())
                        } else {
                            Text("注册已关闭")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            // --- FIX END ---
            .onAppear {
                viewModel.checkRegistrationStatus()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
