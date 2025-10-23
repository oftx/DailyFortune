import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var avatarUrl: String = ""
    @Published var backgroundUrl: String = ""
    @Published var language: String = ""
    @Published var timezone: String = ""
    @Published var qq: String = ""
    @Published var useQqAvatar: Bool = false
    
    @Published var isLoading = false
    @Published var successMessage: String?
    @Published var errorMessage: String?

    func load(user: UserMeProfile) {
        self.displayName = user.displayName
        self.bio = user.bio
        self.avatarUrl = user.avatarUrl
        self.backgroundUrl = user.backgroundUrl
        self.language = user.language
        self.timezone = user.timezone
        self.qq = user.qq.map { String($0) } ?? ""
        self.useQqAvatar = user.useQqAvatar
    }
    
    func saveChanges(authManager: AuthManager) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let payload = UserUpdatePayload(
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            backgroundUrl: backgroundUrl,
            language: language,
            timezone: timezone,
            qq: Int(qq),
            useQqAvatar: useQqAvatar
        )
        
        Task {
            do {
                let response = try await APIService.shared.updateMyProfile(payload: payload)
                authManager.updateUser(response.user)
                self.successMessage = "设置已成功保存！"
            } catch {
                self.errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var isChangePasswordSheetPresented = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("个人资料")) {
                    TextField("显示名称", text: $viewModel.displayName)
                    // --- FIX START: Replace iOS 16 vertical axis TextField ---
                    TextField("个人简介", text: $viewModel.bio)
                    // --- FIX END ---
                    TextField("头像图片链接", text: $viewModel.avatarUrl).keyboardType(.URL)
                    TextField("主页背景图片链接", text: $viewModel.backgroundUrl).keyboardType(.URL)
                    
                    // --- FIX START: Replace iOS 16 LabeledContent ---
                    HStack {
                        Text("用户ID")
                        Spacer()
                        Text(authManager.currentUser?.username ?? "").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("电子邮箱")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "").foregroundColor(.secondary)
                    }
                    // --- FIX END ---
                }
                
                Section(header: Text("QQ设置"), footer: Text("重要提示：启用后，您的QQ号将包含在公开的头像链接中，并对他人可见。")) {
                    TextField("QQ号", text: $viewModel.qq).keyboardType(.numberPad)
                    Toggle("将QQ头像作为个人资料头像", isOn: $viewModel.useQqAvatar)
                }
                
                Section(header: Text("偏好设置")) {
                    Picker("语言", selection: $viewModel.language) {
                        Text("简体中文").tag("zh")
                        Text("English").tag("en")
                    }

                    Picker("时区", selection: $viewModel.timezone) {
                        ForEach(Constants.timezones, id: \.self) { tz in
                            Text(tz).tag(tz)
                        }
                    }
                }
                
                Section(header: Text("安全")) {
                    Button("更改密码") {
                        isChangePasswordSheetPresented = true
                    }
                }
                
                if let message = viewModel.successMessage {
                    Text(message).foregroundColor(.green)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundColor(.red)
                }
                
                Section {
                    // --- FIX START: Replace iOS 15 Button with role ---
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("登出")
                            .foregroundColor(.red)
                    }
                    // --- FIX END ---
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.saveChanges(authManager: authManager)
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("保存")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    viewModel.load(user: user)
                }
            }
            .sheet(isPresented: $isChangePasswordSheetPresented) {
                ChangePasswordView()
            }
        }
        .navigationViewStyle(.stack)
    }
}
