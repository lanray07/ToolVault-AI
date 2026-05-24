import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: SubscriptionService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ToolVaultHeader("Upgrade ToolVault AI", subtitle: "Unlock scanner workflows, reports, resale tracking, team assignments, and business controls.")

                    planCard(
                        plan: .free,
                        price: "Free",
                        features: [
                            "25 tools",
                            "Basic inventory tracking",
                            "Limited reports",
                            "ToolVault AI branding"
                        ]
                    )

                    planCard(
                        plan: .pro,
                        price: subscriptions.product(for: .pro)?.displayPrice ?? subscriptions.placeholderPrice(for: .pro),
                        features: [
                            "Unlimited tools",
                            "AI tool scanner",
                            "Maintenance reminders",
                            "PDF exports",
                            "Resale tracking",
                            "Theft reports"
                        ]
                    )

                    planCard(
                        plan: .business,
                        price: subscriptions.product(for: .business)?.displayPrice ?? subscriptions.placeholderPrice(for: .business),
                        features: [
                            "Team assignments",
                            "Advanced reports",
                            "Custom branding placeholder",
                            "Multi-user placeholder",
                            "Bulk import placeholder"
                        ]
                    )

                    DisclaimerBox()
                }
                .padding()
            }
            .toolVaultScreenBackground()
            .navigationTitle("Paywall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ToolVaultTheme.accentOrange)
                }
            }
            .task {
                await subscriptions.loadProducts()
            }
        }
    }

    private func planCard(plan: SubscriptionPlan, price: String, features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ToolVaultTheme.accentOrange)
                }
                Spacer()
                if subscriptions.plan == plan && subscriptions.isActive {
                    Text("Active")
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.82))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ToolVaultTheme.positive)
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
            }

            if plan != .free {
                Button {
                    if let product = subscriptions.product(for: plan) {
                        Task { await subscriptions.purchase(product) }
                    } else {
                        subscriptions.errorMessage = "Configure StoreKit products to enable purchases."
                    }
                } label: {
                    if subscriptions.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Choose \(plan.rawValue)")
                    }
                }
                .buttonStyle(ToolVaultPrimaryButtonStyle())
            }
        }
        .toolVaultCard()
    }
}
