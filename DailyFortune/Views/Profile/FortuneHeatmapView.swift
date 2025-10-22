import SwiftUI

struct FortuneHeatmapView: View {
    let history: [FortuneHistoryItem]
    private let days: [Date], historyDict: [String: FortuneHistoryItem], columnStartIndices: [Int]

    init(history: [FortuneHistoryItem]) {
        self.history = history
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.days = Array((0..<365).map { calendar.date(byAdding: .day, value: -$0, to: today)! }.reversed())
        self.historyDict = Dictionary(uniqueKeysWithValues: history.map { (calendar.startOfDay(for: $0.createdAt).toShortDateString(), $0) })
        self.columnStartIndices = Array(stride(from: 0, to: days.count, by: 7))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 2) {
                    ForEach(columnStartIndices, id: \.self) { startIndex in columnView(for: startIndex) }
                }
                .padding()
                .id("heatmap_content")
            }
            .onAppear { proxy.scrollTo("heatmap_content", anchor: .trailing) }
        }
        .frame(height: 15 * 7 + 2 * 6 + 30)
        .background(Color(UIColor.systemGray5).opacity(0.8))
        .cornerRadius(10)
    }

    @ViewBuilder private func columnView(for columnStartIndex: Int) -> some View {
        VStack(spacing: 2) { ForEach(0..<7) { rowIndex in cellView(for: columnStartIndex + rowIndex) } }
    }
    
    @ViewBuilder private func cellView(for dayIndex: Int) -> some View {
        if dayIndex < days.count {
            let date = days[dayIndex]
            let dateString = date.toShortDateString()
            let fortuneItem = historyDict[dateString]
            let level = Constants.Heatmap.colorLevels[fortuneItem?.value ?? ""] ?? 0
            let color = Constants.Heatmap.colorScale[level]
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 15, height: 15)
        } else {
            Rectangle().fill(Color.clear).frame(width: 15, height: 15)
        }
    }
}
