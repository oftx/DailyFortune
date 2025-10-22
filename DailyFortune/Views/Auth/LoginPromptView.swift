import SwiftUI
struct LoginPromptView: View {
    @State private var isShowingLoginSheet = false
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark").font(.system(size: 80)).foregroundColor(.secondary)
            Text("请先登录").font(.title).fontWeight(.bold)
            Text("登录后可查看个人资料、同步运势历史并进行设置.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Button("登录 / 注册") { isShowingLoginSheet.toggle() }
            .ifavailable_borderedProminent()
            .padding()
        }
        .sheet(isPresented: $isShowingLoginSheet) { LoginView() }
    }
}
