import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 4) {
                            Text("Tideline")
                                .font(.largeTitle.weight(.bold))
                            Text("Ride your daily mood wave")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // Today's entry card
                        GridView()
                            .padding(.horizontal, 16)

                        // Stats row
                        HStack(spacing: 12) {
                            MetricTile(
                                value: appModel.todayEntry.map { "\($0.level)" } ?? "-",
                                label: "Today"
                            )
                            MetricTile(
                                value: String(format: "%.1f", appModel.sevenDayAverage),
                                label: "7-day avg"
                            )
                            MetricTile(
                                value: "\(appModel.currentStreak)",
                                label: "Streak"
                            )
                        }
                        .padding(.horizontal, 16)

                        // Pro tile
                        Button {
                            if store.isPro {
                                showInsights = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.isPro ? "Tideline Pro" : "Unlock Insights")
                                        .font(.headline)
                                    Text(store.isPro ? "History, dual-wave & trends" : "Multi-month history + dual-wave")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isPro ? "waveform.path.ecg" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                                    .font(.title3)
                            }
                            .qmCard()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .onAppear {
                handleForceScreen()
            }
        }
    }

    private func handleForceScreen() {
        guard let screen = forceScreen else { return }
        switch screen {
        case "paywall": showPaywall = true
        case "insights": showInsights = true
        case "settings": showSettings = true
        default: break
        }
    }
}
