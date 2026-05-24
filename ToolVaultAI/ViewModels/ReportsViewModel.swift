import Combine
import Foundation
import SwiftData

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var selectedReportType: InventoryReportType = .fullInventory
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedURL: URL?

    private let pdfService = PDFReportService()

    @discardableResult
    func generateReport(
        context: ModelContext,
        tools: [ToolItem],
        maintenanceRecords: [MaintenanceRecord],
        theftReports: [TheftReport]
    ) async -> InventoryReport? {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let url = try pdfService.generateReport(
                type: selectedReportType,
                tools: tools,
                maintenanceRecords: maintenanceRecords,
                theftReports: theftReports
            )
            let report = InventoryReport(
                title: "\(selectedReportType.rawValue) - \(Date().toolVaultShortDate)",
                reportType: selectedReportType,
                pdfLocalURL: url.path
            )
            context.insert(report)
            try context.save()
            generatedURL = url
            errorMessage = nil
            return report
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
