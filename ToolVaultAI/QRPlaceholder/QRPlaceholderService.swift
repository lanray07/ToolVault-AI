import Foundation
import SwiftUI

struct QRLabelPayload: Identifiable, Hashable {
    let id = UUID()
    let toolId: UUID
    let displayName: String
    let serialNumber: String
    let encodedPayload: String
}

protocol QRLabelService: Sendable {
    func makeLabelPayload(for tool: ToolItem) -> QRLabelPayload
}

struct MockQRLabelService: QRLabelService {
    func makeLabelPayload(for tool: ToolItem) -> QRLabelPayload {
        QRLabelPayload(
            toolId: tool.id,
            displayName: tool.toolName,
            serialNumber: tool.serialNumber,
            encodedPayload: "toolvault://tool/\(tool.id.uuidString)"
        )
    }
}

private struct QRLabelServiceKey: EnvironmentKey {
    static let defaultValue: any QRLabelService = MockQRLabelService()
}

extension EnvironmentValues {
    var qrLabelService: any QRLabelService {
        get { self[QRLabelServiceKey.self] }
        set { self[QRLabelServiceKey.self] = newValue }
    }
}
