import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()

                List {
                    // Pro section
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Text("Tideline Pro")
                                Spacer()
                                Text("Active")
                                    .foregroundStyle(Color.qmCorrect)
                                    .font(.subheadline.weight(.medium))
                            }
                            Link("Manage Subscription",
                                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Unlock Tideline Pro") {
                                showPaywall = true
                            }
                            .foregroundStyle(Color.qmAccent)
                        }

                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .foregroundStyle(Color.qmAccent)
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: theme) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("Legal") {
                        Link("Privacy Policy",
                             destination: URL(string: "https://shimondeitel.github.io/tideline-site/privacy.html")!)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Data
                    Section("Data") {
                        Button("Delete All Data") {
                            showDeleteConfirm = true
                        }
                        .foregroundStyle(Color.qmWrong)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete all Tideline data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    appModel.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all your logged energy entries and cannot be undone.")
            }
        }
    }
}
