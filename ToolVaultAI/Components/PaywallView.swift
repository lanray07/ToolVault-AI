import StoreKit
import SwiftUI

private struct SubscriptionDisplayOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let billingPeriod: String
    let features: [String]
    let plan: SubscriptionPlan
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: SubscriptionService

    private let privacyURL = URL(string: "https://github.com/lanray07/ToolVault-AI/blob/main/PRIVACY_POLICY.md")!
    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private let subscriptionOptions: [SubscriptionDisplayOption] = [
        SubscriptionDisplayOption(
            id: SubscriptionService.proMonthlyID,
            title: "ToolVault AI Pro Monthly",
            subtitle: "Pro tools for individual tradespeople and technicians.",
            billingPeriod: "Auto-renews monthly",
            features: [
                "Unlimited tools",
                "AI tool scanner",
                "Maintenance reminders",
                "PDF exports",
                "Resale tracking",
                "Theft reports"
            ],
            plan: .pro
        ),
        SubscriptionDisplayOption(
            id: SubscriptionService.proYearlyID,
            title: "ToolVault AI Pro Yearly",
            subtitle: "Annual Pro access for users who want the best Pro value.",
            billingPeriod: "Auto-renews yearly",
            features: [
                "Unlimited tools",
                "AI tool scanner",
                "Maintenance reminders",
                "PDF exports",
                "Resale tracking",
                "Theft reports"
            ],
            plan: .pro
        ),
        SubscriptionDisplayOption(
            id: SubscriptionService.businessMonthlyID,
            title: "ToolVault AI Business Monthly",
            subtitle: "Business workflows for contractors and tool-owning teams.",
            billingPeriod: "Auto-renews monthly",
            features: [
                "Team assignments",
                "Advanced reports",
                "Custom branding placeholder",
                "Multi-user placeholder",
                "Bulk import placeholder"
            ],
            plan: .business
        )
    ]

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

                    ForEach(subscriptionOptions) { option in
                        subscriptionCard(option: option)
                    }

                    if let errorMessage = subscriptions.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(ToolVaultTheme.warning)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .toolVaultCard()
                    }

                    subscriptionTerms

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

    private func subscriptionCard(option: SubscriptionDisplayOption) -> some View {
        let product = subscriptions.product(id: option.id)
        let price = product?.displayPrice ?? subscriptions.placeholderPrice(forProductID: option.id)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(option.subtitle)
                        .font(.footnote)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                    Text("\(price) - \(option.billingPeriod)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ToolVaultTheme.accentOrange)
                }
                Spacer()
                if subscriptions.plan == option.plan && subscriptions.isActive {
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
                ForEach(option.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
            }

            Button {
                if let product {
                    Task { await subscriptions.purchase(product) }
                } else {
                    subscriptions.errorMessage = "This subscription is not available from App Store Connect yet. Product ID: \(option.id)"
                }
            } label: {
                if subscriptions.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe to \(option.title)")
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .buttonStyle(ToolVaultPrimaryButtonStyle())
            .accessibilityHint("Purchases \(option.title), \(price), \(option.billingPeriod).")
        }
        .toolVaultCard()
    }

    private var subscriptionTerms: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscription terms")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current billing period. Purchases and cancellations are managed with your Apple ID in App Store account settings.")
                .font(.footnote)
                .foregroundStyle(ToolVaultTheme.mutedText)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: privacyURL)
                Link("Terms of Use (EULA)", destination: eulaURL)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ToolVaultTheme.accentOrange)
        }
        .toolVaultCard()
    }
}
