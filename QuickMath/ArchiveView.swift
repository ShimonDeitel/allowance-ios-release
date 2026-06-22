import SwiftUI
import Charts

// MARK: - InsightsView (Pro)

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var selectedEnvelopeID: UUID? = nil
    @State private var showExportSheet = false
    @State private var exportCSV = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        if appModel.envelopes.isEmpty {
                            Text("No envelopes to show insights for.")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        } else {
                            overviewSection
                            spendTrendsSection
                            envelopePickerSection
                            if let eid = selectedEnvelopeID ?? appModel.envelopes.first?.id {
                                envelopeHistorySection(envelopeID: eid)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportCSV = buildCSV()
                        showExportSheet = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [exportCSV])
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Period")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                MetricTile(value: formatCurrency(appModel.totalAllocated()), label: "Budget")
                MetricTile(value: formatCurrency(appModel.totalSpent()), label: "Spent")
                MetricTile(value: formatCurrency(appModel.totalRemaining()), label: "Remaining")
            }
        }
    }

    // MARK: - Spend trends chart

    private var spendTrendsSection: some View {
        let data = appModel.envelopes.map { e in
            SpendBar(name: e.name, spent: appModel.spent(for: e),
                     budget: e.allocation, color: e.colorTag.tagColor)
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Spend by Category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Chart(data) { bar in
                BarMark(
                    x: .value("Envelope", bar.name),
                    y: .value("Spent", bar.spent)
                )
                .foregroundStyle(Color.qmAccent)

                RuleMark(
                    x: .value("Envelope", bar.name),
                    y: .value("Budget", bar.budget)
                )
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                .foregroundStyle(Color.qmHair)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .qmCard()
    }

    // MARK: - Envelope picker

    private var envelopePickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(appModel.envelopes) { e in
                    let isSelected = (selectedEnvelopeID ?? appModel.envelopes.first?.id) == e.id
                    Button {
                        selectedEnvelopeID = e.id
                        Haptics.tap()
                    } label: {
                        Text(e.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isSelected ? .white : Color.qmAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.qmAccent : Color.qmCard,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Per-envelope history

    private func envelopeHistorySection(envelopeID: UUID) -> some View {
        let allSpends = appModel.allSpendsForEnvelope(envelopeID)
        let envelopeName = appModel.envelopes.first(where: { $0.id == envelopeID })?.name ?? "Envelope"
        let total = allSpends.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(envelopeName + " — All Spends")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCurrency(total) + " total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if allSpends.isEmpty {
                Text("No spends recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(allSpends.prefix(50)) { spend in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spend.note.isEmpty ? "Spend" : spend.note)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text(spend.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatCurrency(spend.amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.qmWrong)
                    }
                    Divider()
                }
            }
        }
        .qmCard()
    }

    // MARK: - CSV Export

    private func buildCSV() -> String {
        var lines = ["Envelope,Amount,Note,Date"]
        let envelopeMap = Dictionary(uniqueKeysWithValues: appModel.envelopes.map { ($0.id, $0.name) })
        let formatter = ISO8601DateFormatter()
        for spend in appModel.spends {
            let eName = envelopeMap[spend.envelopeID] ?? spend.envelopeID.uuidString
            let dateStr = formatter.string(from: spend.date)
            let noteClean = spend.note.replacingOccurrences(of: ",", with: " ")
            lines.append("\(eName),\(spend.amount),\(noteClean),\(dateStr)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Chart data

private struct SpendBar: Identifiable {
    let id = UUID()
    let name: String
    let spent: Double
    let budget: Double
    let color: Color
}

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
