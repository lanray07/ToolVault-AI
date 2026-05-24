import Foundation
import SwiftUI

enum ToolVaultAIPrompt {
    static let system = "You are ToolVault AI, an assistant for tool inventory and asset tracking. Review uploaded tool photos, condition notes, maintenance history, and inventory details. Generate estimated condition summaries, resale ranges, and maintenance insights using cautious, non-definitive language. Do not provide insurance valuations, guarantees, or financial advice."
}

struct ToolAIAnalysis: Identifiable, Hashable {
    var id = UUID()
    var identifiedTool: String
    var possibleCategory: ToolCategory
    var possibleBrand: String
    var possibleModel: String
    var conditionEstimate: ToolCondition
    var estimatedResaleRange: String
    var estimatedLowValue: Double
    var estimatedHighValue: Double
    var visibleWear: String
    var insights: [String]
    var summary: String
}

protocol AIService: Sendable {
    func analyzeToolPhoto(imageData: Data?, notes: String) async throws -> ToolAIAnalysis
    func estimateResaleValue(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String
    func generateConditionSummary(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String
    func generateInventoryInsights(tools: [ToolItem], maintenanceRecords: [MaintenanceRecord]) async throws -> [String]
}

enum AIServiceError: LocalizedError {
    case invalidResponse
    case missingEndpoint

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "ToolVault AI could not read the AI response."
        case .missingEndpoint:
            return "Remote AI is not configured. Mock AI is enabled by default."
        }
    }
}

struct MockAIService: AIService {
    func analyzeToolPhoto(imageData: Data?, notes: String) async throws -> ToolAIAnalysis {
        try await Task.sleep(nanoseconds: 650_000_000)
        let lowerNotes = notes.lowercased()
        let category: ToolCategory
        let brand: String

        if lowerNotes.contains("drill") || lowerNotes.contains("impact") {
            category = .powerTools
            brand = lowerNotes.contains("dewalt") ? "DEWALT" : "Possible power tool brand"
        } else if lowerNotes.contains("ladder") {
            category = .ladders
            brand = "Possible ladder manufacturer"
        } else if lowerNotes.contains("meter") || lowerNotes.contains("laser") {
            category = .measuringTools
            brand = "Possible measuring tool brand"
        } else {
            category = .powerTools
            brand = "Possible visible brand"
        }

        return ToolAIAnalysis(
            identifiedTool: "Possible \(category.rawValue.lowercased()) item",
            possibleCategory: category,
            possibleBrand: brand,
            possibleModel: "Possible model not confirmed",
            conditionEstimate: .good,
            estimatedResaleRange: "Estimated resale range: £80 - £180",
            estimatedLowValue: 80,
            estimatedHighValue: 180,
            visibleWear: imageData == nil ? "No photo provided. Condition is based on notes only." : "Visible signs of wear appear moderate. Verify in person before relying on this estimate.",
            insights: [
                "Capture the serial number and receipt for insurance-ready records.",
                "Add maintenance history to improve future resale estimates.",
                "Use cautious resale estimates because local market prices may vary."
            ],
            summary: "This appears to be a \(category.rawValue.lowercased()) asset. The condition estimate is informational only and should be independently verified."
        )
    }

    func estimateResaleValue(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String {
        try await Task.sleep(nanoseconds: 350_000_000)
        let conditionFactor: Double
        switch tool.currentCondition {
        case .new:
            conditionFactor = 0.82
        case .excellent:
            conditionFactor = 0.72
        case .good:
            conditionFactor = 0.58
        case .fair:
            conditionFactor = 0.42
        case .poor:
            conditionFactor = 0.28
        case .damaged:
            conditionFactor = 0.16
        case .missing:
            conditionFactor = 0
        }
        let maintenanceBoost = maintenanceRecords.isEmpty ? 0 : 0.06
        let midpoint = max(tool.purchasePrice * min(conditionFactor + maintenanceBoost, 0.9), tool.estimatedResaleValue)
        let low = midpoint * 0.85
        let high = midpoint * 1.15
        return "Estimated resale range: \(low.gbpFormatted) - \(high.gbpFormatted). This is informational only and not a valuation guarantee."
    }

    func generateConditionSummary(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String {
        let serviceCount = maintenanceRecords.count
        let maintenancePhrase = serviceCount == 0
            ? "No maintenance logs are stored yet."
            : "\(serviceCount) maintenance log\(serviceCount == 1 ? "" : "s") may support the stated condition."
        return "\(tool.toolName) is currently marked \(tool.currentCondition.rawValue). \(maintenancePhrase) Verify physical condition, serial number, and accessories before resale or insurance use."
    }

    func generateInventoryInsights(tools: [ToolItem], maintenanceRecords: [MaintenanceRecord]) async throws -> [String] {
        let totalValue = tools.reduce(0) { $0 + $1.estimatedResaleValue }
        let highValueCount = tools.filter(\.isHighValue).count
        let maintenanceCount = tools.filter(\.needsMaintenanceAttention).count
        return [
            "Estimated tracked resale value is \(totalValue.gbpFormatted), based on local records and mock AI assumptions.",
            "\(highValueCount) high-value tools should have serial numbers, photos, and receipt records.",
            "\(maintenanceCount) tools may need maintenance attention based on current condition."
        ]
    }
}

struct RemoteAIService: AIService {
    private let endpoint: URL

    init(endpoint: URL? = URL(string: "https://YOUR_BACKEND_URL.com/toolvault-ai")) {
        self.endpoint = endpoint ?? URL(string: "https://YOUR_BACKEND_URL.com/toolvault-ai")!
    }

    func analyzeToolPhoto(imageData: Data?, notes: String) async throws -> ToolAIAnalysis {
        try await performRequest(
            module: "scanner",
            toolCategory: "",
            toolNotes: notes,
            condition: "",
            imageData: imageData
        )
    }

    func estimateResaleValue(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String {
        let response = try await performRequest(
            module: "resale",
            toolCategory: tool.category.rawValue,
            toolNotes: tool.notes,
            condition: tool.currentCondition.rawValue,
            imageData: nil
        )
        return response.estimatedResaleRange
    }

    func generateConditionSummary(tool: ToolItem, maintenanceRecords: [MaintenanceRecord]) async throws -> String {
        let response = try await performRequest(
            module: "condition",
            toolCategory: tool.category.rawValue,
            toolNotes: tool.notes,
            condition: tool.currentCondition.rawValue,
            imageData: nil
        )
        return response.summary
    }

    func generateInventoryInsights(tools: [ToolItem], maintenanceRecords: [MaintenanceRecord]) async throws -> [String] {
        let notes = tools.map { "\($0.toolName): \($0.category.rawValue), \($0.currentCondition.rawValue), \($0.estimatedResaleValue.gbpFormatted)" }
            .joined(separator: "\n")
        let response = try await performRequest(
            module: "inventoryInsights",
            toolCategory: "",
            toolNotes: notes,
            condition: "",
            imageData: nil
        )
        return response.insights
    }

    private func performRequest(
        module: String,
        toolCategory: String,
        toolNotes: String,
        condition: String,
        imageData: Data?
    ) async throws -> ToolAIAnalysis {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RemoteAIRequest(
            module: module,
            toolCategory: toolCategory,
            toolNotes: toolNotes,
            condition: condition,
            imageBase64: imageData?.base64EncodedString() ?? ""
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AIServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(RemoteAIResponse.self, from: data)
        let category = ToolCategory(rawValue: toolCategory) ?? .custom
        return ToolAIAnalysis(
            identifiedTool: decoded.identifiedTool,
            possibleCategory: category,
            possibleBrand: decoded.identifiedTool,
            possibleModel: "Possible model not confirmed",
            conditionEstimate: ToolCondition(rawValue: decoded.conditionEstimate) ?? .good,
            estimatedResaleRange: decoded.estimatedResaleRange,
            estimatedLowValue: 0,
            estimatedHighValue: 0,
            visibleWear: decoded.summary,
            insights: decoded.insights,
            summary: decoded.summary
        )
    }
}

private struct RemoteAIRequest: Encodable {
    let module: String
    let toolCategory: String
    let toolNotes: String
    let condition: String
    let imageBase64: String
}

private struct RemoteAIResponse: Decodable {
    let identifiedTool: String
    let conditionEstimate: String
    let estimatedResaleRange: String
    let insights: [String]
    let summary: String
}

private struct AIServiceKey: EnvironmentKey {
    static let defaultValue: any AIService = MockAIService()
}

extension EnvironmentValues {
    var aiService: any AIService {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}
