import SwiftData
import SwiftUI

struct InventoryReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptions: SubscriptionService

    @Query(sort: \ToolItem.createdAt, order: .reverse) private var tools: [ToolItem]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @Query(sort: \TheftReport.dateReported, order: .reverse) private var theftReports: [TheftReport]
    @Query(sort: \InventoryReport.createdAt, order: .reverse) private var reports: [InventoryReport]

    @StateObject private var viewModel = ReportsViewModel()
    @State private var showPaywall = false
    @State private var sharePayload: SharePayload?

    private var selectedTypeAllowed: Bool {
        subscriptions.plan != .free || viewModel.selectedReportType == .fullInventory || viewModel.selectedReportType == .highValueAssets
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Reports", subtitle: "Generate PDF inventory, maintenance, theft, insurance-ready, and resale summaries.")

                if subscriptions.plan == .free {
                    UpgradeBanner(title: "Limited reports", message: "Upgrade for theft reports, resale summaries, maintenance PDFs, and advanced exports.") {
                        showPaywall = true
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    FieldLabel(title: "Report type")
                    Picker("Report type", selection: $viewModel.selectedReportType) {
                        ForEach(InventoryReportType.allCases) { reportType in
                            Text(reportType.rawValue).tag(reportType)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(ToolVaultTheme.elevatedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button {
                        Task {
                            if let report = await viewModel.generateReport(
                                context: modelContext,
                                tools: tools,
                                maintenanceRecords: maintenanceRecords,
                                theftReports: theftReports
                            ) {
                                sharePayload = SharePayload(items: [URL(fileURLWithPath: report.pdfLocalURL)])
                            }
                        }
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Generate PDF", systemImage: "doc.badge.plus")
                        }
                    }
                    .buttonStyle(ToolVaultPrimaryButtonStyle())
                    .disabled(tools.isEmpty || !selectedTypeAllowed)

                    if !selectedTypeAllowed {
                        Text("This report type is available on Pro and Business plans.")
                            .font(.caption)
                            .foregroundStyle(ToolVaultTheme.warning)
                    }
                }
                .toolVaultCard()

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Generated reports")
                    if reports.isEmpty {
                        EmptyStateView(icon: "doc.text", title: "No reports yet", message: "Generate a PDF report for inventory, insurance-ready export, theft, resale, or maintenance workflows.")
                    } else {
                        ForEach(reports) { report in
                            ReportPreviewView(report: report) { url in
                                sharePayload = SharePayload(items: [url])
                            }
                        }
                    }
                }

                DisclaimerBox()
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
    }
}
