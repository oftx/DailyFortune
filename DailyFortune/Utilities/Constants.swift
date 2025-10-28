import SwiftUI

struct Constants {
    struct FortuneColors {
        
        private static let uiColors: [String: UIColor] = [
            "諭吉": UIColor(hex: "#eec54b"),
            "大吉": UIColor(hex: "#C73E3A"),
            "吉":   UIColor(hex: "#9cca26"),
            "中吉": UIColor(hex: "#eaaa66"),
            "小吉": UIColor(hex: "#4cd3cf"),
            "凶":   UIColor(hex: "#67278F"),
            "大凶": UIColor(hex: "#1A297E")
        ]
        
        static func color(for fortune: String?) -> Color {
            guard let fortune = fortune, let baseColor = uiColors[fortune] else {
                return .gray
            }
            
            let dynamicColor = UIColor { (traitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var brightness: CGFloat = 0
                    var alpha: CGFloat = 0
                    
                    baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                    
                    let darkBrightness = brightness * 0.7
                    let darkSaturation = saturation * 0.9
                    
                    return UIColor(hue: hue, saturation: darkSaturation, brightness: darkBrightness, alpha: alpha)
                } else {
                    return baseColor
                }
            }
            
            return Color(dynamicColor)
        }
    }
    
    // --- 热力图颜色修改开始 ---
    struct Heatmap {
        // 等级映射保持不变
        static let colorLevels: [String: Int] = [
            "大凶": 1,
            "凶": 2,
            "小吉": 3,
            "中吉": 4,
            "吉": 5,
            "大吉": 6,
            "諭吉": 7,
        ]
        
        // --- 变化 1: 定义亮色模式下的颜色数组 (来自 CSS .react-calendar-heatmap) ---
        // Level 0 (无数据) 我们继续使用自适应的 systemGray5
        private static let lightColorHex: [String] = [
            "",      // Level 0 placeholder
            "#d32f2f", // Level 1 (大凶)
            "#e57373", // Level 2 (凶)
            "#aceebb", // Level 3 (小吉)
            "#78d593", // Level 4 (中吉)
            "#4ac26b", // Level 5 (吉)
            "#2da44e", // Level 6 (大吉)
            "#116329", // Level 7 (諭吉)
        ]

        // --- 变化 2: 定义暗色模式下的颜色数组 (来自 CSS body[data-theme='dark']) ---
        private static let darkColorHex: [String] = [
            "",      // Level 0 placeholder
            "#ef9a9a", // Level 1
            "#e57373", // Level 2
            "#033a16", // Level 3
            "#196c2e", // Level 4
            "#2ea043", // Level 5
            "#42bb53", // Level 6
            "#56d364", // Level 7
        ]
        
        // --- 变化 3: 将 colorScale 从静态 let 数组改为动态计算 var 属性 ---
        static var colorScale: [Color] {
            // 使用 map 遍历 0-7 共 8 个等级来创建动态颜色数组
            return (0...7).map { level in
                // Level 0 (无数据) 的颜色保持不变
                if level == 0 {
                    return Color(uiColor: .systemGray5)
                }
                
                // 从Hex颜色数组中获取对应等级的颜色值
                let lightHex = lightColorHex[level]
                let darkHex = darkColorHex[level]
                
                // 创建一个动态 UIColor，它会根据系统模式自动选择颜色
                let dynamicColor = UIColor { (traitCollection) -> UIColor in
                    if traitCollection.userInterfaceStyle == .dark {
                        // 暗色模式
                        return UIColor(hex: darkHex)
                    } else {
                        // 亮色模式
                        return UIColor(hex: lightHex)
                    }
                }
                
                // 将动态 UIColor 转换为 SwiftUI Color
                return Color(dynamicColor)
            }
        }
    }
    // --- 热力图颜色修改结束 ---
    
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
// (这部分扩展代码无需任何修改)

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
