import SwiftUI

struct FortuneHeatmapView: View {
    let history: [FortuneHistoryItem]
    
    private let calendar = Calendar.current
    private let daysInYear = 365
    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<daysInYear).map {
            calendar.date(byAdding: .day, value: -$0, to: today)!
        }.reversed()
    }
    
    private var historyDict: [String: FortuneHistoryItem] {
        Dictionary(uniqueKeysWithValues: history.map { (calendar.startOfDay(for: $0.createdAt).toShortDateString(), $0) })
    }
    
    let rows = Array(repeating: GridItem(.fixed(15), spacing: 2), count: 7)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: 2) {
                 ForEach(days, id: \.self) { date in
                     let dateString = date.toShortDateString()
                     let fortuneItem = historyDict[dateString]
                     
                     let level = Constants.Heatmap.colorLevels[fortuneItem?.value ?? ""] ?? 0
                     let color = Constants.Heatmap.colorScale[level]

                     Rectangle()
                         .fill(color)
                         .cornerRadius(3)
                         .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                         )
                 }
             }
             .padding()
        }
        .frame(height: 15 * 7 + 2 * 6 + 30) // 7 cells, 6 spacings, padding
        .background(.thinMaterial)
        .cornerRadius(10)
    }
}
