import SwiftUI
import SwiftData

// MARK: - GridView: Envelope detail / log spend screen

struct EnvelopeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    let envelope: Envelope

    @State private var showLogSpend = false
    @State private var showEditEnvelope = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        balanceCard
                        logButton
                        spendList
                    }
                    .padding(16)
                }
            }
            .navigationTitle(envelope.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Envelope") {
                            showEditEnvelope = true
                        }
                        Button("Delete Envelope", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showLogSpend) {
            LogSpendView(envelopeID: envelope.id, envelopeName: envelope.name)
                .environmentObject(appModel)
        }
        .sheet(isPresented: $showEditEnvelope) {
            EnvelopeFormView(mode: .edit(envelope))
                .environmentObject(appModel)
        }
        .alert("Delete \(envelope.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                appModel.deleteEnvelope(envelope)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All spends in this envelope will be removed.")
        }
    }

    // MARK: - Balance card

    private var balanceCard: some View {
        let remaining = appModel.remaining(for: envelope)
        let spent = appModel.spent(for: envelope)
        let pct = appModel.percentUsed(for: envelope)
        let isOver = remaining < 0

        return VStack(spacing: 14) {
            HStack {
                Circle()
                    .fill(envelope.colorTag.tagColor)
                    .frame(width: 12, height: 12)
                Text(envelope.cadence.label + " envelope")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatCurrency(remaining))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(isOver ? Color.qmWrong : Color.qmCorrect)
                Text("left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.qmField)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOver ? Color.qmWrong : envelope.colorTag.tagColor)
                        .frame(width: geo.size.width * CGFloat(min(pct, 1.0)), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                MetricTile(value: formatCurrency(spent), label: "Spent")
                MetricTile(value: formatCurrency(envelope.allocation), label: "Budget")
                MetricTile(value: String(format: "%.0f%%", pct * 100), label: "Used")
            }
        }
        .qmCard()
    }

    // MARK: - Log spend button

    private var logButton: some View {
        Button {
            showLogSpend = true
            Haptics.tap()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log a Spend")
            }
            .frame(maxWidth: .infinity)
        }
        .prominentButton()
    }

    // MARK: - Spend list

    private var spendList: some View {
        let items = appModel.spendsForEnvelope(envelope.id)
        return VStack(alignment: .leading, spacing: 10) {
            if items.isEmpty {
                Text("No spends this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Text("This period")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(items) { spend in
                    SpendRowView(spend: spend)
                        .environmentObject(appModel)
                }
            }
        }
    }
}

// MARK: - Spend row

struct SpendRowView: View {
    @EnvironmentObject var appModel: AppModel
    let spend: SpendEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(spend.note.isEmpty ? "Spend" : spend.note)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(spend.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("-\(formatCurrency(spend.amount))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.qmWrong)
        }
        .qmCard(cornerRadius: 14)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                appModel.deleteSpend(spend)
                Haptics.warning()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
}

// MARK: - Log Spend sheet

struct LogSpendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appModel: AppModel

    let envelopeID: UUID
    let envelopeName: String

    @State private var amountText = ""
    @State private var note = ""
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("$")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .qmCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note (optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Grocery run", text: $note)
                            .font(.body)
                    }
                    .qmCard()

                    Spacer()

                    Button("Log Spend") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        appModel.logSpend(envelopeID: envelopeID, amount: amount, note: note)
                        Haptics.success()
                        dismiss()
                    }
                    .prominentButton()
                    .disabled(Double(amountText) == nil || Double(amountText) == 0)
                }
                .padding(20)
            }
            .navigationTitle("Log Spend — \(envelopeName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onAppear { amountFocused = true }
        }
    }
}

// MARK: - Envelope Form (Add / Edit)

enum EnvelopeFormMode {
    case add
    case edit(Envelope)
}

struct EnvelopeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appModel: AppModel

    let mode: EnvelopeFormMode

    @State private var name: String = ""
    @State private var allocationText: String = ""
    @State private var cadence: CadenceType = .monthly
    @State private var colorTag: String = "blue"

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Groceries", text: $name)
                            .font(.body)
                    }
                    .qmCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Budget Amount")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $allocationText)
                                .keyboardType(.decimalPad)
                        }
                        .font(.body)
                    }
                    .qmCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cadence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Cadence", selection: $cadence) {
                            ForEach(CadenceType.allCases, id: \.self) { c in
                                Text(c.label).tag(c)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .qmCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(colorTagOptions, id: \.0) { tag, _ in
                                Circle()
                                    .fill(tag.tagColor)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorTag == tag ? 2 : 0)
                                            .padding(-2)
                                    )
                                    .onTapGesture {
                                        colorTag = tag
                                        Haptics.tap()
                                    }
                            }
                        }
                    }
                    .qmCard()

                    Spacer()

                    Button(isEditing ? "Save Changes" : "Add Envelope") {
                        save()
                    }
                    .prominentButton()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || Double(allocationText) == nil)
                }
                .padding(20)
            }
            .navigationTitle(isEditing ? "Edit Envelope" : "New Envelope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        if case .edit(let e) = mode {
            name = e.name
            allocationText = String(format: "%.2f", e.allocation)
            cadence = e.cadence
            colorTag = e.colorTag
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, let amount = Double(allocationText), amount > 0 else { return }

        switch mode {
        case .add:
            appModel.addEnvelope(name: trimmedName, allocation: amount,
                                 cadence: cadence, colorTag: colorTag)
        case .edit(let e):
            appModel.updateEnvelope(e, name: trimmedName, allocation: amount,
                                    cadence: cadence, colorTag: colorTag)
        }
        Haptics.success()
        dismiss()
    }
}
