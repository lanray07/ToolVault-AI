import Foundation
import SwiftUI

struct NFCTagPayload: Identifiable, Hashable {
    let id = UUID()
    let toolId: UUID
    let displayName: String
    let payload: String
    let notes: String
}

protocol NFCTagService: Sendable {
    func makeTagPayload(for tool: ToolItem) -> NFCTagPayload
}

struct MockNFCTagService: NFCTagService {
    func makeTagPayload(for tool: ToolItem) -> NFCTagPayload {
        NFCTagPayload(
            toolId: tool.id,
            displayName: tool.toolName,
            payload: "toolvault-nfc:\(tool.id.uuidString)",
            notes: "NFC writing is a placeholder architecture. Add Core NFC writer implementation when hardware and entitlement flow are ready."
        )
    }
}

private struct NFCTagServiceKey: EnvironmentKey {
    static let defaultValue: any NFCTagService = MockNFCTagService()
}

extension EnvironmentValues {
    var nfcTagService: any NFCTagService {
        get { self[NFCTagServiceKey.self] }
        set { self[NFCTagServiceKey.self] = newValue }
    }
}
