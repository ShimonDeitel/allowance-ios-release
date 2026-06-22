import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store

    private let benefits: [String] = [
        "Rollover unused cash to next period and unlimited envelopes",
        "Period history with spend-by-category insights and trends",
        "Low-envelope alerts, refill reminders, and CSV export"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 24) {
                    Spacer()

                    // Icon + title
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundStyle(Color.qmAccent)

                        Text("Allowance Pro")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)

                        Text("$0.99 / month. Auto-renews until you cancel.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Benefits
                    VStack(spacing: 12) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.qmCorrect)
                                    .font(.body)
                                Text(benefit)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                    .qmCard()

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            Haptics.tap()
                            Task { await store.purchase() }
                        } label: {
                            HStack {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Unlock for \(store.displayPrice)/mo")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        Button("Restore Purchase") {
                            Haptics.tap()
                            Task { await store.restore() }
                        }
                        .softButton()

                        Button {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Manage Subscription")
                                .font(.footnote)
                                .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // Disclosure
                    VStack(spacing: 6) {
                        Text("Subscription automatically renews monthly at $0.99 unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription at any time in your Apple ID Settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button("Terms") {
                                if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Button("Privacy") {
                                if let url = URL(string: "https://shimondeitel.github.io/allowance-site/privacy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.qmAccent)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}
