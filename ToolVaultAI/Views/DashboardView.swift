import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.aiService) private var aiService
    @EnvironmentObject private var subscriptions: SubscriptionService

    @Query(sort: \ToolItem.createdAt, order: .reverse) private var tools: [ToolItem]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @Query(sort: \TheftReport.dateReported, order: .reverse) private var theftReports: [TheftReport]

    @StateObject private var viewModel = DashboardViewModel()
    @State private var showAddTool = false
    @State private var showPaywall = false

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let metrics = viewModel.metrics(tools: tools, maintenanceRecords: maintenanceRecords, theftReports: theftReports)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ToolVaultHeader("ToolVault AI", subtitle: "Your tool inventory command center.")

                UpgradeBanner(
                    title: subscriptions.statusText,
                    message: subscriptions.plan == .free ? "Free plan supports 25 tools and limited reports." : "Premium workflows are unlocked for this device.",
                    action: { showPaywall = true }
                )

                LazyVGrid(columns: metricColumns, spacing: 12) {
                    InventoryValueCard(title: "Total Tools", value: "\(metrics.totalTools)", icon: "shippingbox.fill", tint: ToolVaultTheme.accentOrange)
                    InventoryValueCard(title: "Estimated Value", value: metrics.totalEstimatedValue.gbpFormatted, icon: "sterlingsign.circle.fill", tint: ToolVaultTheme.positive)
                    InventoryValueCard(title: "High-Value Tools", value: "\(metrics.highValueTools)", icon: "shield.lefthalf.filled", tint: ToolVaultTheme.steelBlue)
                    InventoryValueCard(title: "Maintenance Needed", value: "\(metrics.maintenanceAttention)", icon: "wrench.adjustable.fill", tint: ToolVaultTheme.warning)
                    InventoryValueCard(title: "Recently Added", value: "\(metrics.recentlyAddedTools)", icon: "clock.badge.checkmark.fill", tint: ToolVaultTheme.positive)
                    InventoryValueCard(title: "Missing Tools", value: "\(metrics.missingTools)", icon: "exclamationmark.lock.fill", tint: ToolVaultTheme.danger, subtitle: "Theft module placeholder ready")
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Quick actions")
                    LazyVGrid(columns: metricColumns, spacing: 12) {
                        Button { showAddTool = true } label: {
                            QuickActionTile(title: "Add Tool", icon: "plus.circle.fill")
                        }
                        NavigationLink { AIToolScannerView() } label: {
                            QuickActionTile(title: "Scan Tool", icon: "camera.viewfinder")
                        }
                        NavigationLink { InventoryReportsView() } label: {
                            QuickActionTile(title: "Generate Report", icon: "doc.badge.plus")
                        }
                        NavigationLink { MaintenanceTrackerView() } label: {
                            QuickActionTile(title: "Maintenance Check", icon: "wrench.and.screwdriver.fill")
                        }
                        NavigationLink { TeamAssignmentView() } label: {
                            QuickActionTile(title: "Assign Tool", icon: "person.crop.circle.badge.plus")
                        }
                        NavigationLink { AlertsView() } label: {
                            QuickActionTile(title: "View Alerts", icon: "bell.badge.fill")
                        }
                    }
                }

                if viewModel.isLoadingInsights {
                    LoadingStateView(message: "Generating inventory insights")
                } else if !viewModel.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Mock AI insights")
                        ForEach(viewModel.insights, id: \.self) { insight in
                            Label(insight, systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(ToolVaultTheme.mutedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .toolVaultCard()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Recently added")
                    if tools.isEmpty {
                        EmptyStateView(icon: "shippingbox", title: "No tools yet", message: "Add your first asset to start tracking condition, value, and theft-ready records.", actionTitle: "Add Tool") {
                            showAddTool = true
                        }
                    } else {
                        ForEach(tools.prefix(4)) { tool in
                            NavigationLink {
                                ToolDetailView(tool: tool)
                            } label: {
                                ToolCard(tool: tool)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddTool) {
            NavigationStack { ToolFormView() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task(id: tools.map(\.id)) {
            await viewModel.refreshInsights(aiService: aiService, tools: tools, maintenanceRecords: maintenanceRecords)
        }
    }
}

private struct QuickActionTile: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(ToolVaultTheme.accentOrange)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .toolVaultCard()
    }
}
