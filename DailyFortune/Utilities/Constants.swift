import SwiftUI

struct Constants {
    struct FortuneColors {
        
        // --- FIX START: 更新颜色以匹配Web前端，并为暗色模式做准备 ---
        // 1. 我们将基础颜色存储为 UIColor，因为它更便于进行亮度/饱和度计算。
        private static let uiColors: [String: UIColor] = [
            "諭吉": UIColor(hex: "#eec54b"),
            "大吉": UIColor(hex: "#C73E3A"),
            "吉":   UIColor(hex: "#9cca26"),
            "中吉": UIColor(hex: "#eaaa66"),
            "小吉": UIColor(hex: "#4cd3cf"),
            "凶":   UIColor(hex: "#67278F"),
            "大凶": UIColor(hex: "#1A297E")
        ]
        
        /// 返回一个能自动适应亮/暗模式的动态颜色。
        /// 在暗色模式下，颜色会自动变暗。
        static func color(for fortune: String?) -> Color {
            guard let fortune = fortune, let baseColor = uiColors[fortune] else {
                return .gray
            }
            
            // 2. 创建一个动态的 UIColor。
            // SwiftUI 会在界面模式切换时自动重新调用这个闭包。
            let dynamicColor = UIColor { (traitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    // 3. 在暗色模式下，降低亮度和饱和度以获得更好的视觉效果。
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var brightness: CGFloat = 0
                    var alpha: CGFloat = 0
                    
                    baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                    
                    // 降低亮度和饱和度的系数可以根据视觉效果微调
                    let darkBrightness = brightness * 0.7
                    let darkSaturation = saturation * 0.9
                    
                    return UIColor(hue: hue, saturation: darkSaturation, brightness: darkBrightness, alpha: alpha)
                } else {
                    // 4. 在亮色模式下，返回原始颜色。
                    return baseColor
                }
            }
            
            // 5. 将动态的 UIColor 转换为 SwiftUI 的 Color。
            return Color(dynamicColor)
        }
        // --- FIX END ---
    }
    
    // 热力图颜色保持不变
    struct Heatmap {
        static let colorLevels: [String: Int] = [
            "大凶": 1,
            "凶": 2,
            "小吉": 3,
            "中吉": 4,
            "吉": 5,
            "大吉": 6,
            "諭吉": 7,
        ]
        
        static let colorScale: [Color] = [
            Color(uiColor: .systemGray5), // Level 0 (no data)
            Color(red: 0.6, green: 0, blue: 0), // 大凶
            Color(red: 0.8, green: 0.2, blue: 0.2), // 凶
            Color(red: 0.9, green: 0.9, blue: 0.4), // 小吉
            Color(red: 0.6, green: 0.9, blue: 0.6), // 中吉
            Color(red: 0.4, green: 0.8, blue: 0.4), // 吉
            Color(red: 0.2, green: 0.7, blue: 0.2), // 大吉
            Color(red: 1.0, green: 0.84, blue: 0)   // 諭吉 (Gold)
        ]
    }
    
    static let timezones: [String] = [
      "UTC",
      "Asia/Shanghai",
      "Asia/Tokyo",
      "Europe/London",
      "Europe/Paris",
      "America/New_York",
      "America/Chicago",
      "America/Los_Angeles"
    ]
}

// MARK: - Color/UIColor Hex Initializer Extensions

// --- FIX: 为 UIColor 添加 hex 初始化方法 ---
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
