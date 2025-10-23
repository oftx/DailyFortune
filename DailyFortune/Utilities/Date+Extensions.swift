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
}
