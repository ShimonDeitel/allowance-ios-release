import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro section
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmCorrect)
                                Text("Allowance Pro — Active")
                                    .foregroundStyle(.primary)
                            }
                            Button("Manage Subscription") {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundStyle(Color.qmAccent)
                        } else {
                            Button {
                                showPaywall = true
                                Haptics.tap()
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Unlock Allowance Pro")
                                        .foregroundStyle(Color.qmAccent)
                                }
                            }
                            Button("Restore Purchase") {
                                Haptics.tap()
                                Task { await store.restore() }
                            }
                            .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Links
                    Section("Legal") {
                        Button("Privacy Policy") {
                            if let url = URL(string: "https://shimondeitel.github.io/allowance-site/privacy.html") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(Color.qmAccent)

                        Button("Terms of Service") {
                            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(Color.qmAccent)
                    }

                    // Data
                    Section("Data") {
                        Button("Delete All Data", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                appModel.deleteAllData()
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all envelopes and spends.")
        }
    }
}
