import SwiftData
import SwiftUI

@main
struct ToolVaultAIApp: App {
    @StateObject private var subscriptions = SubscriptionService()
    @StateObject private var notifications = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(subscriptions)
                .environmentObject(notifications)
                .environment(\.aiService, MockAIService())
                .environment(\.qrLabelService, MockQRLabelService())
                .environment(\.nfcTagService, MockNFCTagService())
                .modelContainer(for: [
                    ToolItem.self,
                    ToolPhoto.self,
                    MaintenanceRecord.self,
                    AssignmentRecord.self,
                    TheftReport.self,
                    InventoryReport.self,
                    SubscriptionState.self,
                    ValueHistoryRecord.self
                ])
        }
    }
}
