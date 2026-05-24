import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var notifications: NotificationService

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("tradeType") private var tradeType = TradeType.electrician.rawValue
    @AppStorage("teamSetup") private var teamSetup = TeamSetup.solo.rawValue
    @AppStorage("approximateToolCount") private var approximateToolCount = "25"
    @AppStorage("mainGoal") private var mainGoal = OnboardingGoal.inventoryTracking.rawValue

    @Query private var tools: [ToolItem]
    @Query private var photos: [ToolPhoto]
    @Query private var maintenanceRecords: [MaintenanceRecord]
    @Query private var assignments: [AssignmentRecord]
    @Query private var theftReports: [TheftReport]
    @Query private var reports: [InventoryReport]
    @Query private var subscriptionStates: [SubscriptionState]
    @Query private var valueHistory: [ValueHistoryRecord]

    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var sharePayload: SharePayload?
    @State private var policyText: PolicyText?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Settings", subtitle: "Subscriptions, notifications, exports, placeholders, legal text, and data controls.")

                settingsGroup("Account") {
                    SettingsRow(icon: "creditcard.fill", title: "Subscription", subtitle: subscriptions.statusText) {
                        showPaywall = true
                    }
                    SettingsRow(icon: "arrow.clockwise.circle.fill", title: "Restore Purchases", subtitle: "StoreKit 2 restore scaffold") {
                        Task { await subscriptions.restorePurchases() }
                    }
                }

                settingsGroup("Notifications") {
                    SettingsRow(icon: "bell.badge.fill", title: notifications.isAuthorized ? "Notifications Enabled" : "Enable Notifications", subtitle: "Maintenance reminders use local notifications") {
                        Task { await notifications.requestAuthorization() }
                    }
                }

                settingsGroup("Data") {
                    SettingsRow(icon: "square.and.arrow.up.fill", title: "Export Data", subtitle: "Share a CSV inventory export") {
                        sharePayload = SharePayload(items: [inventoryCSV()])
                    }
                    SettingsRow(icon: "qrcode", title: "QR Settings Placeholder", subtitle: "QR label architecture is ready for future label rendering") {}
                    SettingsRow(icon: "wave.3.right.circle.fill", title: "NFC Settings Placeholder", subtitle: "Core NFC writer flow can be added behind this service") {}
                }

                settingsGroup("Onboarding Profile") {
                    InfoLine(title: "Trade", value: tradeType)
                    InfoLine(title: "Setup", value: teamSetup)
                    InfoLine(title: "Approximate tools", value: approximateToolCount)
                    InfoLine(title: "Main goal", value: mainGoal)
                    Button("Run Onboarding Again") {
                        hasCompletedOnboarding = false
                    }
                    .buttonStyle(ToolVaultSecondaryButtonStyle())
                }

                settingsGroup("Legal") {
                    SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "Placeholder policy text") {
                        policyText = .privacy
                    }
                    SettingsRow(icon: "doc.plaintext.fill", title: "Terms of Use", subtitle: "Placeholder terms text") {
                        policyText = .terms
                    }
                    SettingsRow(icon: "info.circle.fill", title: "AI Disclaimer", subtitle: "AI estimates are informational only") {
                        policyText = .aiDisclaimer
                    }
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                }
                .buttonStyle(ToolVaultSecondaryButtonStyle())
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .sheet(item: $policyText) { text in
            PolicyTextView(policy: text)
        }
        .confirmationDialog("Delete all local ToolVault AI data?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title)
            content()
        }
        .toolVaultCard()
    }

    private func inventoryCSV() -> String {
        let header = "Tool Name,Category,Brand,Model,Serial,Purchase Date,Purchase Price,Condition,Estimated Resale,Location,Assigned User"
        let rows = tools.map { tool in
            [
                tool.toolName,
                tool.category.rawValue,
                tool.brand,
                tool.model,
                tool.serialNumber,
                tool.purchaseDate.toolVaultShortDate,
                "\(tool.purchasePrice)",
                tool.currentCondition.rawValue,
                "\(tool.estimatedResaleValue)",
                tool.storageLocation,
                tool.assignedUser
            ].map { $0.replacingOccurrences(of: ",", with: " ") }.joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func deleteAllData() {
        tools.forEach { modelContext.delete($0) }
        photos.forEach { modelContext.delete($0) }
        maintenanceRecords.forEach { modelContext.delete($0) }
        assignments.forEach { modelContext.delete($0) }
        theftReports.forEach { modelContext.delete($0) }
        reports.forEach { modelContext.delete($0) }
        subscriptionStates.forEach { modelContext.delete($0) }
        valueHistory.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(ToolVaultTheme.accentOrange)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ToolVaultTheme.mutedText)
            }
        }
        .buttonStyle(.plain)
    }
}

private enum PolicyText: String, Identifiable {
    case privacy
    case terms
    case aiDisclaimer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        case .aiDisclaimer: return "AI Disclaimer"
        }
    }

    var bodyText: String {
        switch self {
        case .privacy:
            return "ToolVault AI stores inventory records locally with SwiftData in this scaffold. Remote AI should be routed through your backend and must not embed API keys in the app."
        case .terms:
            return "This scaffold is provided as a production-ready starting point. Configure legal terms, subscriptions, backend endpoints, and data retention policies before public release."
        case .aiDisclaimer:
            return "AI estimates are informational only. They are not insurance valuations, guarantees, or financial advice. Resale values may vary and users should verify all values independently."
        }
    }
}

private struct PolicyTextView: View {
    @Environment(\.dismiss) private var dismiss
    let policy: PolicyText

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(policy.bodyText)
                    .font(.body)
                    .foregroundStyle(ToolVaultTheme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .toolVaultScreenBackground()
            .navigationTitle(policy.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ToolVaultTheme.accentOrange)
                }
            }
        }
    }
}
