import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showAddEnvelope = false
    @State private var selectedEnvelope: Envelope? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        summaryHeader
                        envelopeList
                        proTile
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Allowance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddEnvelope = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
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
        .sheet(isPresented: $showAddEnvelope) {
            EnvelopeFormView(mode: .add)
                .environmentObject(appModel)
        }
        .sheet(item: $selectedEnvelope) { envelope in
            EnvelopeDetailView(envelope: envelope)
                .environmentObject(appModel)
                .environmentObject(store)
        }
        .onAppear {
            if let fs = forceScreen {
                if fs == "paywall" { showPaywall = true }
                else if fs == "insights" { showInsights = true }
            }
        }
    }

    // MARK: - Summary header

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            MetricTile(value: formatCurrency(appModel.totalRemaining()),
                       label: "Left to Spend")
            MetricTile(value: formatCurrency(appModel.totalSpent()),
                       label: "Spent")
            MetricTile(value: formatCurrency(appModel.totalAllocated()),
                       label: "Budget")
        }
    }

    // MARK: - Envelope list

    private var envelopeList: some View {
        VStack(spacing: 12) {
            if appModel.envelopes.isEmpty {
                emptyState
            } else {
                ForEach(appModel.envelopes) { envelope in
                    EnvelopeRowView(envelope: envelope)
                        .onTapGesture {
                            selectedEnvelope = envelope
                            Haptics.tap()
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.qmAccent)
            Text("No envelopes yet")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Tap + to create your first budget envelope.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Envelope") {
                showAddEnvelope = true
                Haptics.tap()
            }
            .prominentButton()
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pro tile

    private var proTile: some View {
        Button {
            if store.isPro {
                showInsights = true
            } else {
                showPaywall = true
            }
            Haptics.tap()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: store.isPro ? "chart.bar.fill" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(store.isPro ? Color.qmCorrect : Color.qmAccent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.isPro ? "View Insights" : "Allowance Pro")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(store.isPro ? "Period history, trends, and export"
                                    : "Rollover, insights, alerts & export")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Envelope row

struct EnvelopeRowView: View {
    @EnvironmentObject var appModel: AppModel
    let envelope: Envelope

    var body: some View {
        let spentAmt = appModel.spent(for: envelope)
        let remaining = appModel.remaining(for: envelope)
        let pct = appModel.percentUsed(for: envelope)
        let isOver = remaining < 0

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(envelope.colorTag.tagColor)
                    .frame(width: 10, height: 10)
                Text(envelope.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(formatCurrency(remaining))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isOver ? Color.qmWrong : Color.qmCorrect)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.qmField)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isOver ? Color.qmWrong : envelope.colorTag.tagColor)
                        .frame(width: geo.size.width * CGFloat(min(pct, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
            HStack {
                Text("Spent \(formatCurrency(spentAmt)) of \(formatCurrency(envelope.allocation))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(envelope.cadence.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .qmCard()
    }
}
