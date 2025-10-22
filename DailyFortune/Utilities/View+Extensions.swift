import SwiftUI

extension View {
    /// Applies the `.refreshable` modifier only on iOS 15 and above.
    @ViewBuilder
    func ifavailable_refreshable(action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, *) {
            self.refreshable(action: action)
        } else {
            self
        }
    }
    
    /// Applies the `.buttonStyle(.borderedProminent)` on iOS 15+,
    /// with a custom fallback style for iOS 14.
    @ViewBuilder
    func ifavailable_borderedProminent() -> some View {
        if #available(iOS 15.0, *) {
            self.buttonStyle(.borderedProminent)
        } else {
            // Fallback style for iOS 14
            self
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}
