import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ToolFormViewModel: ObservableObject {
    @Published var toolName = ""
    @Published var category: ToolCategory = .powerTools
    @Published var brand = ""
    @Published var model = ""
    @Published var serialNumber = ""
    @Published var purchaseDate = Date()
    @Published var purchasePriceText = ""
    @Published var condition: ToolCondition = .good
    @Published var estimatedResaleValueText = ""
    @Published var storageLocation = ""
    @Published var assignedUser = ""
    @Published var notes = ""
    @Published var receiptPlaceholder = false
    @Published private(set) var photoData: [Data] = []
    @Published var isLoadingPhotos = false
    @Published var errorMessage: String?

    var canSave: Bool {
        !toolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var purchasePrice: Double {
        Double(purchasePriceText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var estimatedResaleValue: Double {
        Double(estimatedResaleValueText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    func setPhotoImporting(_ isImporting: Bool) {
        isLoadingPhotos = isImporting
    }

    func addImportedPhoto(_ data: Data?) {
        guard let data else {
            errorMessage = "One photo could not be imported."
            return
        }
        photoData.append(data)
        errorMessage = nil
    }

    func addCameraPhoto(_ data: Data) {
        photoData.append(data)
    }

    func removePhoto(at offsets: IndexSet) {
        photoData.remove(atOffsets: offsets)
    }

    @discardableResult
    func save(context: ModelContext) throws -> ToolItem {
        let trimmedName = toolName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tool = ToolItem(
            toolName: trimmedName,
            category: category,
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            currentCondition: condition,
            estimatedResaleValue: estimatedResaleValue,
            storageLocation: storageLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedUser: assignedUser.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notesWithReceiptPlaceholder
        )
        context.insert(tool)

        for data in photoData {
            context.insert(ToolPhoto(toolId: tool.id, imageData: data, caption: "Tool photo"))
        }

        if estimatedResaleValue > 0 {
            context.insert(ValueHistoryRecord(
                toolId: tool.id,
                estimatedValue: estimatedResaleValue,
                condition: condition,
                note: "Initial resale estimate"
            ))
        }

        try context.save()
        reset()
        return tool
    }

    private var notesWithReceiptPlaceholder: String {
        var output = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if receiptPlaceholder {
            output += output.isEmpty ? "Receipt placeholder added." : "\nReceipt placeholder added."
        }
        return output
    }

    private func reset() {
        toolName = ""
        category = .powerTools
        brand = ""
        model = ""
        serialNumber = ""
        purchaseDate = Date()
        purchasePriceText = ""
        condition = .good
        estimatedResaleValueText = ""
        storageLocation = ""
        assignedUser = ""
        notes = ""
        receiptPlaceholder = false
        photoData = []
        errorMessage = nil
    }
}
