import Foundation
import SwiftData

// MARK: - SwiftData models

@Model
final class WaveEntry {
    var id: UUID
    var date: Date
    var level: Int
    var partOfDay: String
    var tag: String?

    init(id: UUID = UUID(), date: Date = .now, level: Int, partOfDay: String = "day", tag: String? = nil) {
        self.id = id
        self.date = date
        self.level = level
        self.partOfDay = partOfDay
        self.tag = tag
    }
}

@Model
final class TrendCache {
    var id: UUID
    var weekStart: Date
    var average: Double

    init(id: UUID = UUID(), weekStart: Date, average: Double) {
        self.id = id
        self.weekStart = weekStart
        self.average = average
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var recentEntries: [WaveEntry] = []
    @Published private(set) var todayEntry: WaveEntry? = nil
    @Published private(set) var allEntries: [WaveEntry] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([WaveEntry.self, TrendCache.self])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    func reload() {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<WaveEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let fetched = (try? ctx.fetch(descriptor)) ?? []
        allEntries = fetched
        recentEntries = Array(fetched.prefix(7))
        todayEntry = fetched.first(where: { Calendar.current.isDateInToday($0.date) })
    }

    func refresh() { reload() }

    // MARK: Log energy level
    func logEnergy(level: Int, partOfDay: String = "day", tag: String? = nil) {
        let ctx = container.mainContext
        // Replace existing today entry if same partOfDay
        if let existing = allEntries.first(where: {
            Calendar.current.isDateInToday($0.date) && $0.partOfDay == partOfDay
        }) {
            existing.level = level
            existing.tag = tag
        } else {
            let entry = WaveEntry(level: level, partOfDay: partOfDay, tag: tag)
            ctx.insert(entry)
        }
        try? ctx.save()
        reload()
    }

    // MARK: 7-day rolling average
    var sevenDayAverage: Double {
        let relevant = recentEntries.prefix(7)
        guard !relevant.isEmpty else { return 0 }
        return Double(relevant.map(\.level).reduce(0, +)) / Double(relevant.count)
    }

    // MARK: Best time of day (pro)
    var bestTimeOfDay: String {
        let mornings = allEntries.filter { $0.partOfDay == "morning" }
        let evenings = allEntries.filter { $0.partOfDay == "evening" }
        let morningAvg = mornings.isEmpty ? 0.0 : Double(mornings.map(\.level).reduce(0, +)) / Double(mornings.count)
        let eveningAvg = evenings.isEmpty ? 0.0 : Double(evenings.map(\.level).reduce(0, +)) / Double(evenings.count)
        if morningAvg == 0 && eveningAvg == 0 { return "Not enough data" }
        if morningAvg >= eveningAvg { return "Morning" }
        return "Evening"
    }

    // MARK: Current streak
    var currentStreak: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        let daySet = Set(allEntries.map { Calendar.current.startOfDay(for: $0.date) })
        while daySet.contains(checkDate) {
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: WaveEntry.self)
        try? ctx.delete(model: TrendCache.self)
        try? ctx.save()
        reload()
    }
}
