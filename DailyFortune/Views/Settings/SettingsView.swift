import SwiftUI
import Combine
import UIKit

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

    private var initialUser: UserMeProfile?

    var hasChanges: Bool {
        guard let user = initialUser else { return false }
        
        return displayName != user.displayName ||
               bio != user.bio ||
               avatarUrl != user.avatarUrl ||
               backgroundUrl != user.backgroundUrl ||
               language != user.language ||
               timezone != user.timezone ||
               (Int(qq) ?? 0) != (user.qq ?? 0) ||
               useQqAvatar != user.useQqAvatar
    }

    func load(user: UserMeProfile) {
        self.displayName = user.displayName
        self.bio = user.bio
        self.avatarUrl = user.avatarUrl
        self.backgroundUrl = user.backgroundUrl
        self.language = user.language
        self.timezone = user.timezone
        self.qq = user.qq.map { String($0) } ?? ""
        self.useQqAvatar = user.useQqAvatar
        
        self.initialUser = user
    }
    
    func revertChanges() {
        if let user = initialUser {
            load(user: user)
        }
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
                self.load(user: response.user)
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
    @State private var showDiscardConfirm = false
    // --- 新增代码 1: 用于跟踪键盘可见性的状态变量 ---
    @State private var isKeyboardVisible = false

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Form 内容保持不变
                Section(header: Text("个人资料")) {
                    TextField("显示名称", text: $viewModel.displayName)
                    TextField("个人简介", text: $viewModel.bio, axis: .vertical)
                    TextField("头像图片链接", text: $viewModel.avatarUrl).keyboardType(.URL)
                    TextField("主页背景图片链接", text: $viewModel.backgroundUrl).keyboardType(.URL)
                    LabeledContent("用户ID") {
                        Text(authManager.currentUser?.username ?? "").foregroundColor(.secondary)
                    }
                    LabeledContent("电子邮箱") {
                        Text(authManager.currentUser?.email ?? "").foregroundColor(.secondary)
                    }
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
                    Button("登出", role: .destructive) {
                        authManager.logout()
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // --- 变化 1: 仅在键盘可见时显示取消按钮 ---
                    if isKeyboardVisible {
                        Button("取消") {
                            dismissKeyboard()
                            if viewModel.hasChanges {
                                showDiscardConfirm = true
                            } else {
                                viewModel.revertChanges()
                            }
                        }
                        .transition(.opacity.animation(.easeInOut)) // 添加淡入淡出动画
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismissKeyboard()
                        viewModel.saveChanges(authManager: authManager)
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("保存")
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.hasChanges)
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    viewModel.load(user: user)
                }

            }
            // --- 新增代码 2: 使用 .onReceive 监听键盘通知 ---
            .onReceive(
                // 合并 "键盘将显示" 和 "键盘将隐藏" 两个通知流
                Publishers.Merge(
                    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification).map { _ in true },
                    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification).map { _ in false }
                )
                // 确保在主线程上更新状态
                .receive(on: DispatchQueue.main)
            ) { isVisible in
                // 用动画更新状态，使按钮的出现/消失更平滑
                withAnimation {
                    self.isKeyboardVisible = isVisible
                }
            }
            .sheet(isPresented: $isChangePasswordSheetPresented) {
                ChangePasswordView()
            }
            .alert("放弃修改？", isPresented: $showDiscardConfirm) {
                Button("放弃", role: .destructive) {
                    viewModel.revertChanges()
                }
                Button("继续编辑", role: .cancel) { }
            } message: {
                Text("你所做的修改将不会被保存。")
            }
        }
    }
}
