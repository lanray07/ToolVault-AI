import Combine
import Foundation

struct DashboardMetrics {
    let totalTools: Int
    let highValueTools: Int
    let maintenanceAttention: Int
    let recentlyAddedTools: Int
    let missingTools: Int
    let totalEstimatedValue: Double
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var insights: [String] = []
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?

    func metrics(tools: [ToolItem], maintenanceRecords: [MaintenanceRecord], theftReports: [TheftReport]) -> DashboardMetrics {
        let recentThreshold = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let missingIDs = Set(theftReports.map(\.toolId))
        return DashboardMetrics(
            totalTools: tools.count,
            highValueTools: tools.filter(\.isHighValue).count,
            maintenanceAttention: tools.filter(\.needsMaintenanceAttention).count,
            recentlyAddedTools: tools.filter { $0.createdAt >= recentThreshold }.count,
            missingTools: tools.filter { $0.currentCondition == .missing || missingIDs.contains($0.id) }.count,
            totalEstimatedValue: tools.reduce(0) { $0 + $1.estimatedResaleValue }
        )
    }

    func refreshInsights(aiService: any AIService, tools: [ToolItem], maintenanceRecords: [MaintenanceRecord]) async {
        guard !tools.isEmpty else {
            insights = []
            return
        }
        isLoadingInsights = true
        defer { isLoadingInsights = false }
        do {
            insights = try await aiService.generateInventoryInsights(tools: tools, maintenanceRecords: maintenanceRecords)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
