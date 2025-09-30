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

    func login(authManager: AuthManager) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.login(username: username, password: password)
                authManager.login(token: response.accessToken, user: response.user)
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
                .frame(height: 150) // 调整高度以适应布局
                .scrollDisabled(true) // 禁止表单滚动
                
                // --- FIX #3 START ---
                // 将错误信息移出Form，确保完整显示
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                // --- FIX #3 END ---
                
                Button(action: {
                    viewModel.login(authManager: authManager)
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
        }
    }
}
