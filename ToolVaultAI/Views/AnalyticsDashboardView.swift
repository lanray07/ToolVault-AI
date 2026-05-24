import Charts
import SwiftData
import SwiftUI

struct AnalyticsDashboardView: View {
    @Query(sort: \ToolItem.createdAt, order: .reverse) private var tools: [ToolItem]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]

    private var totalInventoryValue: Double {
        tools.reduce(0) { $0 + $1.estimatedResaleValue }
    }

    private var totalMaintenanceCost: Double {
        maintenanceRecords.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Analytics", subtitle: "Inventory value, depreciation, maintenance costs, category mix, and condition breakdown.")

                if tools.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line", title: "No analytics yet", message: "Add tools and maintenance records to build analytics.")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InventoryValueCard(title: "Inventory Value", value: totalInventoryValue.gbpFormatted, icon: "sterlingsign.circle.fill", tint: ToolVaultTheme.positive)
                        InventoryValueCard(title: "Maintenance Costs", value: totalMaintenanceCost.gbpFormatted, icon: "wrench.fill", tint: ToolVaultTheme.warning)
                    }

                    AnalyticsChartCard(title: "Category distribution", subtitle: "Tool count by category") {
                        Chart(categoryData) { item in
                            BarMark(x: .value("Category", item.name), y: .value("Count", item.value))
                                .foregroundStyle(ToolVaultTheme.accentOrange.gradient)
                        }
                    }

                    AnalyticsChartCard(title: "Condition breakdown", subtitle: "Current condition state across inventory") {
                        Chart(conditionData) { item in
                            BarMark(x: .value("Condition", item.name), y: .value("Count", item.value))
                                .foregroundStyle(ToolVaultTheme.steelBlue.gradient)
                        }
                    }

                    AnalyticsChartCard(title: "Depreciation trends", subtitle: "Purchase price versus current estimate") {
                        Chart(depreciationData) { item in
                            BarMark(x: .value("Tool", item.name), y: .value("Purchase", item.purchase))
                                .foregroundStyle(ToolVaultTheme.surfaceLight)
                            BarMark(x: .value("Tool", item.name), y: .value("Current", item.current))
                                .foregroundStyle(ToolVaultTheme.accentOrange)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Most expensive tools")
                        ForEach(tools.sorted { $0.estimatedResaleValue > $1.estimatedResaleValue }.prefix(5)) { tool in
                            ToolCard(tool: tool)
                        }
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categoryData: [SimpleMetric] {
        Dictionary(grouping: tools, by: { $0.category.rawValue })
            .map { SimpleMetric(name: $0.key, value: Double($0.value.count)) }
            .sorted { $0.name < $1.name }
    }

    private var conditionData: [SimpleMetric] {
        Dictionary(grouping: tools, by: { $0.currentCondition.rawValue })
            .map { SimpleMetric(name: $0.key, value: Double($0.value.count)) }
            .sorted { $0.name < $1.name }
    }

    private var depreciationData: [DepreciationMetric] {
        tools.sorted { $0.purchasePrice > $1.purchasePrice }
            .prefix(8)
            .map { DepreciationMetric(name: $0.toolName, purchase: $0.purchasePrice, current: $0.estimatedResaleValue) }
    }
}

private struct SimpleMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
}

private struct DepreciationMetric: Identifiable {
    let id = UUID()
    let name: String
    let purchase: Double
    let current: Double
}
