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
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                if colorScheme == .light {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                }
                
                VStack {
                    Text("每日运势")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 40)

                    if #available(iOS 16.0, *) {
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
                        .scrollContentBackground(.hidden)
                    } else {
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
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    loginButton
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
            .onAppear {
                viewModel.checkRegistrationStatus()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var loginButton: some View {
        Button(action: {
            viewModel.login(authManager: authManager) {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text("登录")
                    .frame(maxWidth: .infinity)
            }
        }
        .ifavailable_borderedProminent()
        .disabled(viewModel.isLoading)
    }
}
