import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("clock.arrow.circlepath", "Unlimited multi-month wave history and zoom"),
        ("waveform.path.ecg", "Morning vs evening dual-wave comparison"),
        ("lightbulb", "Best-time-of-day insights and gentle daily nudge")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        // Icon + title
                        VStack(spacing: 12) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 56, weight: .thin))
                                .foregroundStyle(Color.qmAccent)

                            Text("Tideline Pro")
                                .font(.largeTitle.weight(.bold))

                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        // Benefits
                        VStack(spacing: 0) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                                HStack(spacing: 14) {
                                    Image(systemName: benefit.0)
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 28)
                                    Text(benefit.1)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)

                                if idx < benefits.count - 1 {
                                    Divider().padding(.leading, 58)
                                }
                            }
                        }
                        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 16)

                        // Unlock button
                        Button {
                            Task {
                                await store.purchase()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Unlock for \(store.displayPrice)/month")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)
                        .padding(.horizontal, 16)

                        // Restore
                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.qmAccent)

                        // Legal
                        VStack(spacing: 8) {
                            Text("Subscription automatically renews each month at \(store.displayPrice) unless cancelled at least 24 hours before the renewal date. Manage or cancel anytime in your Apple Account subscriptions.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/tideline-site/privacy.html")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
