import Foundation

extension Date {
    /// 将日期格式化为相对时间字符串 (例如 "5分钟前")
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// 将日期格式化为 "YYYY-MM-DD"
    func toShortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 将日期格式化为 ISO8601 字符串 (e.g., "2023-10-27T10:00:00Z")，兼容 iOS 14
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}
