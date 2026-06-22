import SwiftUI
import Charts

struct GridView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var sliderValue: Double = 5
    @State private var logged = false

    private var chartEntries: [WaveEntry] {
        Array(appModel.recentEntries.reversed())
    }

    var body: some View {
        VStack(spacing: 20) {
            // Wave chart
            if chartEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.qmAccent.opacity(0.4))
                    Text("Log your first energy level below")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(chartEntries.enumerated()), id: \.offset) { idx, entry in
                        AreaMark(
                            x: .value("Day", idx),
                            yStart: .value("Base", 0),
                            yEnd: .value("Level", entry.level)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.qmAccent.opacity(0.25), Color.qmAccent.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Day", idx),
                            y: .value("Level", entry.level)
                        )
                        .foregroundStyle(Color.qmAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Day", idx),
                            y: .value("Level", entry.level)
                        )
                        .foregroundStyle(Color.qmAccent)
                        .symbolSize(36)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [0, 5, 10]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.qmHair)
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }

            // Divider
            Divider()

            // Log energy section
            VStack(spacing: 12) {
                HStack {
                    Text("Energy level")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(sliderValue.rounded()))")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.qmAccent)
                        .monospacedDigit()
                        .frame(width: 32)
                }

                Slider(value: $sliderValue, in: 0...10, step: 1)
                    .tint(Color.qmAccent)
                    .onChange(of: sliderValue) { _, _ in
                        Haptics.tap()
                        logged = false
                    }

                HStack {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    appModel.logEnergy(level: Int(sliderValue.rounded()))
                    Haptics.success()
                    logged = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: logged ? "checkmark" : "waveform.path")
                        Text(logged ? "Logged" : "Log Today's Energy")
                    }
                    .frame(maxWidth: .infinity)
                }
                .prominentButton()
                .disabled(logged)
                .animation(.easeInOut(duration: 0.2), value: logged)
            }
        }
        .qmCard()
        .onAppear {
            if let today = appModel.todayEntry {
                sliderValue = Double(today.level)
                logged = true
            }
        }
    }
}
