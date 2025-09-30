import SwiftUI

struct Constants {
    struct FortuneColors {
        // --- FIX #4 START ---
        // 更新颜色以匹配Web前端
        static let colors: [String: Color] = [
            "諭吉": Color(hex: "#eec54bff"),
            "大吉": Color(hex: "#C73E3A"),
            "吉":   Color(hex: "#9cca26ff"),
            "中吉": Color(hex: "#eaaa66ff"),
            "小吉": Color(hex: "#4cd3cfff"),
            "凶":   Color(hex: "#67278F"),
            "大凶": Color(hex: "#1A297E")
        ]
        // --- FIX #4 END ---
        
        static func color(for fortune: String?) -> Color {
            guard let fortune = fortune, let color = colors[fortune] else {
                return .gray
            }
            return color
        }
    }
    
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
