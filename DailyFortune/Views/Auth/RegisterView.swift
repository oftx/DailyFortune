import SwiftUI
import Combine

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

struct PolicyContent: Identifiable {
    let id: String
    let title: String
    let content: String
}

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var policyToShow: PolicyContent?
    
    // --- FIX START: 监测颜色模式 ---
    @Environment(\.colorScheme) var colorScheme
    // --- FIX END ---
    
    var body: some View {
        // --- FIX START: 使用 ZStack 来控制背景颜色 ---
        ZStack {
            // 在亮色模式下，设置背景为系统分组灰色
            if colorScheme == .light {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            }
            
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
                            Text(.init("我已阅读并同意[《用户协议》](agreement)和[《隐私政策》](privacy)"))
                        }
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
                // 隐藏 Form 的默认背景，以显示 ZStack 中的自定义背景
                .scrollContentBackground(.hidden)
                .environment(\.openURL, OpenURLAction { url in
                    if url.absoluteString == "agreement" {
                        policyToShow = PolicyContent(id: "agreement", title: "用户协议", content: PolicyText.userAgreement)
                        return .handled
                    } else if url.absoluteString == "privacy" {
                        policyToShow = PolicyContent(id: "privacy", title: "隐私政策", content: PolicyText.privacyPolicy)
                        return .handled
                    }
                    return .systemAction
                })
                
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
        }
        // --- FIX END ---
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $policyToShow) { policy in
            NavigationView {
                ScrollView {
                    Text(policy.content)
                        .padding()
                }
                .navigationTitle(policy.title)
                .navigationBarItems(trailing: Button("完成") {
                    policyToShow = nil
                })
            }
        }
    }
}

struct PolicyText {
    static let userAgreement = """
    欢迎使用“每日运势”！

    生效日期：2025年9月26日

    1. 服务描述
    本应用为您提供一个每日抽取运势的娱乐平台。所有运势结果仅供娱乐，不构成任何建议。

    2. 用户行为准则
    您同意不使用本服务进行任何非法活动，或滥用服务资源，包括但不限于使用自动化脚本进行批量注册或攻击服务器。

    3. 账户安全
    您有责任保管好自己的账户密码。任何通过您账户进行的操作都将被视为您本人的行为。

    4. 免责声明
    本服务按“现状”提供，我们不保证服务的绝对稳定、安全或无误。对于因使用本服务而造成的任何直接或间接损失，我们不承担任何责任。

    5. 协议的修改与终止
    我们保留随时修改本协议条款的权利。如果我们认为您违反了本协议，我们有权暂停或终止您的账户。

    感谢您的理解与合作！
    """
    
    static let privacyPolicy = """
    我们非常重视您的隐私。

    生效日期：2025年9月26日

    1. 我们收集的信息
    - 账户信息：您在注册时提供的用户名、电子邮箱地址和哈希处理后的密码。
    - 使用数据：您的运势抽取历史、个人资料信息（如简介、头像链接）以及最近活跃时间。
    - 技术信息：为了提供速率限制等安全功能，我们会处理您的IP地址，但不会将其与您的个人身份信息永久关联。

    2. 信息的使用
    我们收集这些信息是为了：
    - 提供、维护和改进我们的服务。
    - 保护我们的服务和用户，防止欺诈和滥用行为。
    - 与您就账户相关事宜进行沟通。

    3. 信息的共享
    我们承诺不会将您的个人信息出售、交易或转让给任何第三方，除非根据法律法规的要求或为了保护我们的权利。

    4. 数据安全
    我们采取了行业标准的安全措施来保护您的信息，防止未经授权的访问、泄露、篡改或销毁。

    5. 您的权利
    您有权访问和修改您的个人资料信息。您也可以随时选择注销您的账户。

    如果您对本隐私政策有任何疑问，请与我们联系。

    感谢您的信任！
    """
}
