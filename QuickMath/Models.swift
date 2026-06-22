import SwiftUI
import SwiftData

// MARK: - SwiftData models

@Model
final class Envelope {
    var id: UUID
    var name: String
    var allocation: Double
    var cadence: CadenceType
    var periodStart: Date
    var colorTag: String

    init(id: UUID = UUID(), name: String, allocation: Double,
         cadence: CadenceType = .monthly, periodStart: Date = Date(), colorTag: String = "blue") {
        self.id = id
        self.name = name
        self.allocation = allocation
        self.cadence = cadence
        self.periodStart = periodStart
        self.colorTag = colorTag
    }
}

@Model
final class SpendEntry {
    var id: UUID
    var envelopeID: UUID
    var amount: Double
    var note: String
    var date: Date

    init(id: UUID = UUID(), envelopeID: UUID, amount: Double, note: String = "", date: Date = Date()) {
        self.id = id
        self.envelopeID = envelopeID
        self.amount = amount
        self.note = note
        self.date = date
    }
}

@Model
final class BudgetPeriod {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var isClosed: Bool

    init(id: UUID = UUID(), startDate: Date, endDate: Date, isClosed: Bool = false) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isClosed = isClosed
    }
}

// MARK: - Cadence enum

enum CadenceType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"

    var label: String { rawValue.capitalized }
}

// MARK: - App model

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var envelopes: [Envelope] = []
    @Published private(set) var spends: [SpendEntry] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Envelope.self, SpendEntry.self, BudgetPeriod.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))!
        }
    }

    func reload() {
        let ctx = container.mainContext
        envelopes = (try? ctx.fetch(FetchDescriptor<Envelope>(sortBy: [SortDescriptor(\.name)]))) ?? []
        spends = (try? ctx.fetch(FetchDescriptor<SpendEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    func refresh() { reload() }

    // MARK: - Envelope CRUD

    func addEnvelope(name: String, allocation: Double, cadence: CadenceType, colorTag: String) {
        let e = Envelope(name: name, allocation: allocation, cadence: cadence,
                         periodStart: periodStart(cadence: cadence), colorTag: colorTag)
        container.mainContext.insert(e)
        try? container.mainContext.save()
        reload()
    }

    func updateEnvelope(_ envelope: Envelope, name: String, allocation: Double,
                        cadence: CadenceType, colorTag: String) {
        envelope.name = name
        envelope.allocation = allocation
        envelope.cadence = cadence
        envelope.colorTag = colorTag
        try? container.mainContext.save()
        reload()
    }

    func deleteEnvelope(_ envelope: Envelope) {
        // remove associated spends
        let eid = envelope.id
        let toDelete = spends.filter { $0.envelopeID == eid }
        toDelete.forEach { container.mainContext.delete($0) }
        container.mainContext.delete(envelope)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Spend CRUD

    func logSpend(envelopeID: UUID, amount: Double, note: String) {
        let s = SpendEntry(envelopeID: envelopeID, amount: amount, note: note)
        container.mainContext.insert(s)
        try? container.mainContext.save()
        reload()
    }

    func deleteSpend(_ spend: SpendEntry) {
        container.mainContext.delete(spend)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Balance helpers

    /// Returns the period start date for the current cycle.
    private func periodStart(cadence: CadenceType) -> Date {
        let cal = Calendar.current
        let now = Date()
        switch cadence {
        case .weekly:
            return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .monthly:
            return cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        }
    }

    func currentPeriodStart(for envelope: Envelope) -> Date {
        let cal = Calendar.current
        let now = Date()
        switch envelope.cadence {
        case .weekly:
            return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .monthly:
            return cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        }
    }

    func currentPeriodEnd(for envelope: Envelope) -> Date {
        let cal = Calendar.current
        let start = currentPeriodStart(for: envelope)
        switch envelope.cadence {
        case .weekly:
            return cal.date(byAdding: .day, value: 7, to: start) ?? start
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: start) ?? start
        }
    }

    func spent(for envelope: Envelope) -> Double {
        let start = currentPeriodStart(for: envelope)
        let eid = envelope.id
        return spends
            .filter { $0.envelopeID == eid && $0.date >= start }
            .reduce(0) { $0 + $1.amount }
    }

    func remaining(for envelope: Envelope) -> Double {
        envelope.allocation - spent(for: envelope)
    }

    func percentUsed(for envelope: Envelope) -> Double {
        guard envelope.allocation > 0 else { return 0 }
        return min(1.0, spent(for: envelope) / envelope.allocation)
    }

    func spendsForEnvelope(_ envelopeID: UUID) -> [SpendEntry] {
        let start = envelopes.first(where: { $0.id == envelopeID }).map { currentPeriodStart(for: $0) } ?? Date.distantPast
        return spends.filter { $0.envelopeID == envelopeID && $0.date >= start }
            .sorted { $0.date > $1.date }
    }

    func allSpendsForEnvelope(_ envelopeID: UUID) -> [SpendEntry] {
        spends.filter { $0.envelopeID == envelopeID }
            .sorted { $0.date > $1.date }
    }

    func totalAllocated() -> Double {
        envelopes.reduce(0) { $0 + $1.allocation }
    }

    func totalSpent() -> Double {
        envelopes.reduce(0) { $0 + spent(for: $1) }
    }

    func totalRemaining() -> Double {
        totalAllocated() - totalSpent()
    }

    // MARK: - Delete all

    func deleteAllData() {
        spends.forEach { container.mainContext.delete($0) }
        envelopes.forEach { container.mainContext.delete($0) }
        try? container.mainContext.save()
        reload()
    }
}

// MARK: - Color tag helpers

extension String {
    var tagColor: Color {
        switch self {
        case "blue": return Color.qmAccent
        case "green": return Color.qmCorrect
        case "red": return Color.qmWrong
        case "orange": return .orange
        case "purple": return .purple
        case "teal": return .teal
        default: return Color.qmAccent
        }
    }
}

let colorTagOptions: [(String, String)] = [
    ("blue", "Blue"),
    ("green", "Green"),
    ("red", "Red"),
    ("orange", "Orange"),
    ("purple", "Purple"),
    ("teal", "Teal")
]

// MARK: - Currency formatter

let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = 2
    return f
}()

func formatCurrency(_ value: Double) -> String {
    currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
}
