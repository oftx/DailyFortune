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
                    Color(.systemGroupedBackground).ignoresSafeArea()
                }
                
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
                    // --- FIX START: Replace .scrollDisabled and .scrollContentBackground ---
                    .onAppear {
                        // Hide Form background for iOS 14
                        UITableView.appearance().backgroundColor = .clear
                    }
                    .onDisappear {
                        // Restore default Form background
                        UITableView.appearance().backgroundColor = .systemGroupedBackground
                    }
                    // --- FIX END ---
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Button(action: {
                        viewModel.login(authManager: authManager) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        // --- FIX START: Use a frame to keep size consistent with ProgressView ---
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .colorInvert() // Make it white on blue background
                            } else {
                                Text("登录").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        // --- FIX END ---
                    }
                    // --- FIX START: Replace .borderedProminent for iOS 14 ---
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    // --- FIX END ---
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
            .onAppear {
                viewModel.checkRegistrationStatus()
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}
