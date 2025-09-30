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
    
    // --- FIX #3 START: 添加一个闭包，以便在登录成功后通知视图 ---
    func login(authManager: AuthManager, completion: @escaping () -> Void) {
    // --- FIX #3 END ---
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.login(username: username, password: password)
                authManager.login(token: response.accessToken, user: response.user)
                completion() // 调用闭包
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
    // --- FIX #3 START: 获取 dismiss 环境值以关闭 sheet ---
    @Environment(\.dismiss) var dismiss
    // --- FIX #3 END ---

    var body: some View {
        NavigationStack {
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
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        // --- FIX START: 强制视图垂直扩展以显示多行文本 ---
                        .fixedSize(horizontal: false, vertical: true)
                        // --- FIX END ---
                }
                
                Button(action: {
                    // --- FIX #3 START: 登录成功后关闭 sheet ---
                    viewModel.login(authManager: authManager) {
                        dismiss()
                    }
                    // --- FIX #3 END ---
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
            .onAppear {
                viewModel.checkRegistrationStatus()
            }
            // --- FIX #3 START: 添加工具栏和取消按钮 ---
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            // --- FIX #3 END ---
        }
    }
}
