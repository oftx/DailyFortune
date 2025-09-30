import SwiftUI
import Combine // <-- FIX: Added import

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var agreedToTerms = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func register(authManager: AuthManager) {
        guard agreedToTerms else {
            errorMessage = "您必须同意用户协议和隐私政策。"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.register(username: username, email: email, password: password)
                authManager.login(token: response.accessToken, user: response.user)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}


struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("创建账户")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            Form {
                Section(header: Text("账户信息")) {
                    TextField("用户ID*", text: $viewModel.username)
                        .autocapitalization(.none)
                    TextField("电子邮箱*", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("密码 (至少6位)*", text: $viewModel.password)
                }
                
                Section {
                    Toggle(isOn: $viewModel.agreedToTerms) {
                        Text("我已阅读并同意《用户协议》和《隐私政策》")
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Button(action: {
                viewModel.register(authManager: authManager)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("注册")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
    }
}
