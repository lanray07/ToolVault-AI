import Combine
import Foundation
import SwiftData

@MainActor
final class AIScannerViewModel: ObservableObject {
    @Published private(set) var imageData: Data?
    @Published var notes = ""
    @Published private(set) var result: ToolAIAnalysis?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    func setUploadedPhoto(_ data: Data?) {
        guard let data else {
            errorMessage = "The selected photo could not be imported."
            return
        }
        imageData = data
        result = nil
        errorMessage = nil
    }

    func setCameraPhoto(_ data: Data) {
        imageData = data
        result = nil
    }

    func analyze(aiService: any AIService) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            result = try await aiService.analyzeToolPhoto(imageData: imageData, notes: notes)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func saveSuggestedTool(context: ModelContext) throws -> ToolItem? {
        guard let result else { return nil }
        let midpoint = result.estimatedHighValue > 0
            ? (result.estimatedLowValue + result.estimatedHighValue) / 2
            : 0
        let tool = ToolItem(
            toolName: result.identifiedTool,
            category: result.possibleCategory,
            brand: result.possibleBrand,
            model: result.possibleModel,
            purchaseDate: .now,
            purchasePrice: 0,
            currentCondition: result.conditionEstimate,
            estimatedResaleValue: midpoint,
            notes: "\(result.summary)\n\(result.visibleWear)"
        )
        context.insert(tool)
        if let imageData {
            context.insert(ToolPhoto(toolId: tool.id, imageData: imageData, caption: "AI scanner photo"))
        }
        if midpoint > 0 {
            context.insert(ValueHistoryRecord(
                toolId: tool.id,
                estimatedValue: midpoint,
                condition: result.conditionEstimate,
                note: "AI scanner estimate"
            ))
        }
        try context.save()
        return tool
    }
}
