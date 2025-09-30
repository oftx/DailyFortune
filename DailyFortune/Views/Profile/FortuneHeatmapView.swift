import SwiftUI

struct FortuneHeatmapView: View {
    let history: [FortuneHistoryItem]

    private let days: [Date]
    private let historyDict: [String: FortuneHistoryItem]
    private let columnStartIndices: [Int]

    init(history: [FortuneHistoryItem]) {
        self.history = history
        
        let calendar = Calendar.current
        let daysInYear = 365
        let today = calendar.startOfDay(for: Date())

        // --- FIX START: Perform all calculations using local constants first ---

        // 1. Calculate the array of dates locally.
        // We convert the ReversedCollection back to an Array immediately for stability.
        let calculatedDays = Array((0..<daysInYear).map {
            calendar.date(byAdding: .day, value: -$0, to: today)!
        }.reversed())

        // 2. Calculate the history dictionary locally.
        let calculatedHistoryDict = Dictionary(uniqueKeysWithValues: history.map {
            (calendar.startOfDay(for: $0.createdAt).toShortDateString(), $0)
        })

        // 3. Calculate the column indices using the local `calculatedDays` constant.
        let calculatedColumnIndices = Array(stride(from: 0, to: calculatedDays.count, by: 7))

        // 4. Now that all calculations are complete, assign them to the instance properties.
        // This fully initializes the struct in one go, satisfying the compiler.
        self.days = calculatedDays
        self.historyDict = calculatedHistoryDict
        self.columnStartIndices = calculatedColumnIndices
        
        // --- FIX END ---
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 2) {
                    ForEach(columnStartIndices, id: \.self) { startIndex in
                        columnView(for: startIndex)
                            .id(startIndex)
                    }
                }
                .padding()
            }
            .onAppear {
                if let lastColumnIndex = columnStartIndices.last {
                    proxy.scrollTo(lastColumnIndex, anchor: .trailing)
                }
            }
        }
        .frame(height: 15 * 7 + 2 * 6 + 30)
        .background(.thinMaterial)
        .cornerRadius(10)
    }

    // Helper method to build a single column (VStack)
    @ViewBuilder
    private func columnView(for columnStartIndex: Int) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<7) { rowIndex in
                cellView(for: columnStartIndex + rowIndex)
            }
        }
    }
    
    // Helper method to build a single cell (Rectangle)
    @ViewBuilder
    private func cellView(for dayIndex: Int) -> some View {
        if dayIndex < days.count {
            let date = days[dayIndex]
            let dateString = date.toShortDateString()
            let fortuneItem = historyDict[dateString]
            
            let level = Constants.Heatmap.colorLevels[fortuneItem?.value ?? ""] ?? 0
            let color = Constants.Heatmap.colorScale[level]

            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 15, height: 15)
        } else {
            // Fill with a clear rectangle to maintain grid alignment
            Rectangle().fill(Color.clear).frame(width: 15, height: 15)
        }
    }
}
