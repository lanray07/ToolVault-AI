import Charts
import SwiftData
import SwiftUI

struct ResaleValueTrackerView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext

    let focusedTool: ToolItem?

    @Query(sort: \ToolItem.toolName) private var tools: [ToolItem]
    @Query(sort: \ValueHistoryRecord.recordedAt, order: .forward) private var valueHistory: [ValueHistoryRecord]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]

    @State private var selectedToolID: UUID?
    @State private var isRefreshing = false
    @State private var estimateSummary: String?
    @State private var errorMessage: String?

    init(focusedTool: ToolItem? = nil) {
        self.focusedTool = focusedTool
        _selectedToolID = State(initialValue: focusedTool?.id)
    }

    private var selectedTool: ToolItem? {
        tools.first { $0.id == selectedToolID } ?? focusedTool ?? tools.first
    }

    private var selectedHistory: [ValueHistoryRecord] {
        guard let selectedTool else { return [] }
        return valueHistory.filter { $0.toolId == selectedTool.id }
    }

    private var chartPoints: [ValueTrendPoint] {
        guard let selectedTool else { return [] }
        var points = [ValueTrendPoint(date: selectedTool.purchaseDate, value: selectedTool.purchasePrice, label: "Purchase")]
        points += selectedHistory.map { ValueTrendPoint(date: $0.recordedAt, value: $0.estimatedValue, label: "Estimate") }
        points.append(ValueTrendPoint(date: .now, value: selectedTool.estimatedResaleValue, label: "Current"))
        return points.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Resale Value", subtitle: "Track depreciation, condition impact, and marketability placeholders.")

                if tools.isEmpty && focusedTool == nil {
                    EmptyStateView(icon: "sterlingsign.arrow.circlepath", title: "No resale data", message: "Add tools with purchase prices and conditions to start tracking value.")
                } else if let selectedTool {
                    resaleContent(for: selectedTool)
                }

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                DisclaimerBox()
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Resale")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedToolID == nil {
                selectedToolID = focusedTool?.id ?? tools.first?.id
            }
        }
    }

    private func resaleContent(for tool: ToolItem) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            picker("Tool", selection: $selectedToolID) {
                ForEach(tools) { tool in
                    Text(tool.toolName).tag(Optional(tool.id))
                }
                if let focusedTool, !tools.contains(where: { $0.id == focusedTool.id }) {
                    Text(focusedTool.toolName).tag(Optional(focusedTool.id))
                }
            }
            .toolVaultCard()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InventoryValueCard(title: "Purchase Price", value: tool.purchasePrice.gbpFormatted, icon: "creditcard.fill", tint: ToolVaultTheme.steelBlue)
                InventoryValueCard(title: "Current Estimate", value: tool.estimatedResaleValue.gbpFormatted, icon: "sterlingsign.circle.fill", tint: ToolVaultTheme.positive)
                InventoryValueCard(title: "Depreciation", value: tool.depreciationAmount.gbpFormatted, icon: "arrow.down.forward.circle.fill", tint: ToolVaultTheme.warning)
                InventoryValueCard(title: "Marketability", value: marketabilityScore(for: tool), icon: "gauge.medium", tint: ToolVaultTheme.accentOrange, subtitle: "Placeholder score")
            }

            AnalyticsChartCard(title: "Value trend", subtitle: "Purchase price, saved estimates, and current estimate") {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(ToolVaultTheme.accentOrange)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(ToolVaultTheme.steelBlue)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                InfoLine(title: "Condition impact", value: "Current condition is \(tool.currentCondition.rawValue). Better photos, service history, serials, and receipts may improve buyer confidence.")
                InfoLine(title: "Depreciation trend", value: tool.depreciationAmount > 0 ? "Estimated depreciation is \(tool.depreciationAmount.gbpFormatted)." : "No depreciation recorded yet.")
                if let estimateSummary {
                    InfoLine(title: "Latest AI estimate", value: estimateSummary)
                }
                Button {
                    Task { await refreshEstimate(for: tool) }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Refresh AI Estimate", systemImage: "sparkles")
                    }
                }
                .buttonStyle(ToolVaultPrimaryButtonStyle())
            }
            .toolVaultCard()
        }
    }

    private func refreshEstimate(for tool: ToolItem) async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let records = maintenanceRecords.filter { $0.toolId == tool.id }
            estimateSummary = try await aiService.estimateResaleValue(tool: tool, maintenanceRecords: records)
            let base = tool.estimatedResaleValue > 0 ? tool.estimatedResaleValue : tool.purchasePrice * 0.58
            let adjusted = max(0, base * 0.99)
            tool.estimatedResaleValue = adjusted
            tool.updatedAt = .now
            modelContext.insert(ValueHistoryRecord(toolId: tool.id, estimatedValue: adjusted, condition: tool.currentCondition, note: "AI resale refresh"))
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func marketabilityScore(for tool: ToolItem) -> String {
        let base: Int
        switch tool.currentCondition {
        case .new, .excellent:
            base = 90
        case .good:
            base = 76
        case .fair:
            base = 58
        case .poor:
            base = 38
        case .damaged:
            base = 24
        case .missing:
            base = 0
        }
        let serialBoost = tool.serialNumber.isEmpty ? 0 : 5
        return "\(min(base + serialBoost, 98))/100"
    }

    private func picker<Content: View>(_ title: String, selection: Binding<UUID?>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            Picker(title, selection: selection, content: content)
                .pickerStyle(.menu)
                .tint(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ToolVaultTheme.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct ValueTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}
