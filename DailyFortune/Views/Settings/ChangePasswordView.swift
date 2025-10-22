import SwiftUI
import Combine

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var successMessage: String?
    @Published var errorMessage: String?
    
    var passwordsMatch: Bool {
        newPassword == confirmPassword
    }
    
    func changePassword(completion: @escaping (Bool) -> Void) {
        guard passwordsMatch else {
            errorMessage = "两次输入的新密码不一致。"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await APIService.shared.changePassword(current: currentPassword, new: newPassword)
                successMessage = "密码修改成功！"
                completion(true)
            } catch {
                errorMessage = error.localizedDescription
                completion(false)
            }
            isLoading = false
        }
    }
}


struct ChangePasswordView: View {
    @StateObject private var viewModel = ChangePasswordViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("更改密码")) {
                    SecureField("当前密码", text: $viewModel.currentPassword)
                    SecureField("新密码 (至少6位)", text: $viewModel.newPassword)
                    SecureField("确认新密码", text: $viewModel.confirmPassword)
                }
                
                if !viewModel.passwordsMatch && !viewModel.confirmPassword.isEmpty {
                     Text("新密码不匹配。")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if let message = viewModel.successMessage {
                    Text(message).foregroundColor(.green)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundColor(.red)
                }
            }
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确认修改") {
                        viewModel.changePassword { success in
                            if success {
                                // 延迟关闭以显示成功消息
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}
