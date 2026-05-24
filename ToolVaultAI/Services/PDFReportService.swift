import Foundation
import UIKit

enum PDFReportError: LocalizedError {
    case couldNotWrite

    var errorDescription: String? {
        "ToolVault AI could not generate the PDF report."
    }
}

@MainActor
final class PDFReportService {
    func generateReport(
        type: InventoryReportType,
        tools: [ToolItem],
        maintenanceRecords: [MaintenanceRecord],
        theftReports: [TheftReport]
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let reportTools = filteredTools(for: type, tools: tools, theftReports: theftReports)
        let reportTitle = "ToolVault AI - \(type.rawValue)"

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40
            draw(reportTitle, at: CGRect(x: 40, y: y, width: 532, height: 34), font: .boldSystemFont(ofSize: 22), color: .label)
            y += 38
            draw("Generated \(Date().formatted(date: .abbreviated, time: .shortened))", at: CGRect(x: 40, y: y, width: 532, height: 22), font: .systemFont(ofSize: 11), color: .secondaryLabel)
            y += 32
            draw("AI estimates are informational only. This report is not an insurance valuation, guarantee, or financial advice. Verify values independently.", at: CGRect(x: 40, y: y, width: 532, height: 50), font: .systemFont(ofSize: 11), color: .secondaryLabel)
            y += 62

            let totalValue = reportTools.reduce(0) { $0 + $1.estimatedResaleValue }
            draw("Tracked tools: \(reportTools.count)", at: CGRect(x: 40, y: y, width: 250, height: 22), font: .boldSystemFont(ofSize: 13), color: .label)
            draw("Estimated resale value: \(totalValue.gbpFormatted)", at: CGRect(x: 300, y: y, width: 250, height: 22), font: .boldSystemFont(ofSize: 13), color: .label)
            y += 36

            for tool in reportTools {
                if y > 710 {
                    context.beginPage()
                    y = 40
                }
                let detail = [
                    tool.category.rawValue,
                    tool.currentCondition.rawValue,
                    tool.brand,
                    tool.model,
                    tool.serialNumber.isEmpty ? "No serial recorded" : "Serial: \(tool.serialNumber)",
                    tool.storageLocation.isEmpty ? "No location recorded" : "Location: \(tool.storageLocation)",
                    "Purchase: \(tool.purchasePrice.gbpFormatted)",
                    "Estimated resale: \(tool.estimatedResaleValue.gbpFormatted)"
                ].filter { !$0.isEmpty }.joined(separator: " | ")

                draw(tool.toolName, at: CGRect(x: 40, y: y, width: 532, height: 20), font: .boldSystemFont(ofSize: 14), color: .label)
                y += 20
                draw(detail, at: CGRect(x: 40, y: y, width: 532, height: 38), font: .systemFont(ofSize: 10), color: .secondaryLabel)
                y += 48
            }

            if type == .maintenanceSummary {
                y = appendMaintenanceSection(maintenanceRecords, context: context, y: y)
            }

            if type == .stolenMissingTools || type == .insuranceReadyExport {
                _ = appendTheftSection(theftReports, context: context, y: y)
            }
        }

        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = directory.appendingPathComponent("toolvault-\(type.fileSlug)-\(UUID().uuidString.prefix(8)).pdf")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw PDFReportError.couldNotWrite
        }
    }

    private func filteredTools(for type: InventoryReportType, tools: [ToolItem], theftReports: [TheftReport]) -> [ToolItem] {
        switch type {
        case .fullInventory, .insuranceReadyExport, .maintenanceSummary, .resaleValuationSummary:
            return tools
        case .highValueAssets:
            return tools.filter(\.isHighValue)
        case .stolenMissingTools:
            let missingIDs = Set(theftReports.map(\.toolId)).union(tools.filter { $0.currentCondition == .missing }.map(\.id))
            return tools.filter { missingIDs.contains($0.id) }
        }
    }

    private func appendMaintenanceSection(_ records: [MaintenanceRecord], context: UIGraphicsPDFRendererContext, y startY: CGFloat) -> CGFloat {
        var y = startY + 10
        if y > 700 {
            context.beginPage()
            y = 40
        }
        draw("Maintenance Summary", at: CGRect(x: 40, y: y, width: 532, height: 22), font: .boldSystemFont(ofSize: 16), color: .label)
        y += 28
        for record in records.prefix(24) {
            draw("\(record.maintenanceType.rawValue) - \(record.maintenanceDate.toolVaultShortDate) - \(record.cost.gbpFormatted)", at: CGRect(x: 40, y: y, width: 532, height: 18), font: .systemFont(ofSize: 10), color: .secondaryLabel)
            y += 18
        }
        return y
    }

    private func appendTheftSection(_ reports: [TheftReport], context: UIGraphicsPDFRendererContext, y startY: CGFloat) -> CGFloat {
        var y = startY + 10
        if y > 700 {
            context.beginPage()
            y = 40
        }
        draw("Missing and Theft Reports", at: CGRect(x: 40, y: y, width: 532, height: 22), font: .boldSystemFont(ofSize: 16), color: .label)
        y += 28
        for report in reports.prefix(24) {
            draw("\(report.status.rawValue) - \(report.dateReported.toolVaultShortDate) - \(report.lastKnownLocation)", at: CGRect(x: 40, y: y, width: 532, height: 18), font: .systemFont(ofSize: 10), color: .secondaryLabel)
            y += 18
        }
        return y
    }

    private func draw(_ text: String, at rect: CGRect, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }
}
