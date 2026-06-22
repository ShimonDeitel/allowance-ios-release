import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSegment = 0
    private let segments = ["History", "Dual Wave", "Insights"]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()

                if !store.isPro {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.qmAccent)
                        Text("Tideline Pro Required")
                            .font(.title2.weight(.bold))
                        Text("Unlock multi-month history, dual-wave comparison and insights.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                        Button("Dismiss") { dismiss() }
                            .softButton()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Picker("View", selection: $selectedSegment) {
                                ForEach(0..<segments.count, id: \.self) { i in
                                    Text(segments[i]).tag(i)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)

                            switch selectedSegment {
                            case 0: historySection
                            case 1: dualWaveSection
                            default: insightsSection
                            }

                            Spacer(minLength: 32)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - History
    private var historySection: some View {
        VStack(spacing: 16) {
            // Full history chart
            if appModel.allEntries.isEmpty {
                Text("No data yet. Start logging your energy each day.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(32)
            } else {
                let sorted = appModel.allEntries.sorted { $0.date < $1.date }
                Chart {
                    ForEach(Array(sorted.enumerated()), id: \.offset) { idx, entry in
                        LineMark(
                            x: .value("Day", idx),
                            y: .value("Level", entry.level)
                        )
                        .foregroundStyle(Color.qmAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Day", idx),
                            yStart: .value("Base", 0),
                            yEnd: .value("Level", entry.level)
                        )
                        .foregroundStyle(Color.qmAccent.opacity(0.15))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .frame(height: 180)
                .padding(.horizontal, 16)

                // Entry list
                LazyVStack(spacing: 1) {
                    ForEach(sorted.reversed()) { entry in
                        HStack {
                            Text(entry.date, style: .date)
                                .font(.subheadline)
                            Spacer()
                            Text(entry.partOfDay.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(entry.level)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.qmAccent)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.qmCard)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Dual Wave
    private var dualWaveSection: some View {
        VStack(spacing: 16) {
            Text("Morning vs Evening")
                .font(.headline)

            let mornings = appModel.allEntries.filter { $0.partOfDay == "morning" }.sorted { $0.date < $1.date }
            let evenings = appModel.allEntries.filter { $0.partOfDay == "evening" }.sorted { $0.date < $1.date }

            if mornings.isEmpty && evenings.isEmpty {
                Text("Use the morning/evening toggle when logging to see your dual-wave comparison.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(32)
            } else {
                Chart {
                    ForEach(Array(mornings.enumerated()), id: \.offset) { idx, entry in
                        LineMark(
                            x: .value("Day", idx),
                            y: .value("Morning", entry.level),
                            series: .value("Time", "Morning")
                        )
                        .foregroundStyle(Color.qmAccent)
                        .interpolationMethod(.catmullRom)
                    }
                    ForEach(Array(evenings.enumerated()), id: \.offset) { idx, entry in
                        LineMark(
                            x: .value("Day", idx),
                            y: .value("Evening", entry.level),
                            series: .value("Time", "Evening")
                        )
                        .foregroundStyle(Color.qmCorrect)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .chartLegend(.visible)
                .frame(height: 180)
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.qmAccent).frame(width: 10, height: 10)
                        Text("Morning").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.qmCorrect).frame(width: 10, height: 10)
                        Text("Evening").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Insights
    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                MetricTile(
                    value: String(format: "%.1f", appModel.sevenDayAverage),
                    label: "7-day avg"
                )
                MetricTile(
                    value: "\(appModel.currentStreak)",
                    label: "Day streak"
                )
                MetricTile(
                    value: appModel.bestTimeOfDay,
                    label: "Best time"
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Energy Insights")
                    .font(.headline)

                insightRow(
                    icon: "sun.max",
                    title: "Best time of day",
                    value: appModel.bestTimeOfDay
                )
                insightRow(
                    icon: "flame",
                    title: "Current streak",
                    value: "\(appModel.currentStreak) days"
                )
                insightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Total entries",
                    value: "\(appModel.allEntries.count)"
                )
                insightRow(
                    icon: "waveform.path.ecg",
                    title: "Average energy",
                    value: String(format: "%.1f / 10", appModel.sevenDayAverage)
                )
            }
            .qmCard()
        }
        .padding(.horizontal, 16)
    }

    private func insightRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.qmAccent)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
