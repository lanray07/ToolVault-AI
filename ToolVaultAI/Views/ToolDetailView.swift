import SwiftData
import SwiftUI

struct ToolDetailView: View {
    let tool: ToolItem

    @Query private var photos: [ToolPhoto]
    @Query private var maintenanceRecords: [MaintenanceRecord]
    @Query private var assignments: [AssignmentRecord]
    @Query private var theftReports: [TheftReport]
    @Query private var valueHistory: [ValueHistoryRecord]

    init(tool: ToolItem) {
        self.tool = tool
        let toolID = tool.id
        _photos = Query(filter: #Predicate<ToolPhoto> { $0.toolId == toolID }, sort: \ToolPhoto.createdAt, order: .reverse)
        _maintenanceRecords = Query(filter: #Predicate<MaintenanceRecord> { $0.toolId == toolID }, sort: \MaintenanceRecord.maintenanceDate, order: .reverse)
        _assignments = Query(filter: #Predicate<AssignmentRecord> { $0.toolId == toolID }, sort: \AssignmentRecord.assignedDate, order: .reverse)
        _theftReports = Query(filter: #Predicate<TheftReport> { $0.toolId == toolID }, sort: \TheftReport.dateReported, order: .reverse)
        _valueHistory = Query(filter: #Predicate<ValueHistoryRecord> { $0.toolId == toolID }, sort: \ValueHistoryRecord.recordedAt, order: .reverse)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(tool.toolName)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text([tool.brand, tool.model].filter { !$0.isEmpty }.joined(separator: " "))
                                .font(.title3)
                                .foregroundStyle(ToolVaultTheme.mutedText)
                        }
                        Spacer()
                        ConditionBadge(condition: tool.currentCondition)
                    }

                    if photos.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(ToolVaultTheme.elevatedBackground)
                            Image(systemName: tool.category.iconName)
                                .font(.system(size: 52, weight: .bold))
                                .foregroundStyle(ToolVaultTheme.accentOrange)
                        }
                        .frame(height: 210)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(photos) { photo in
                                    if let data = photo.imageData {
                                        PhotoThumbnail(data: data)
                                            .frame(width: 160, height: 160)
                                    }
                                }
                            }
                        }
                    }
                }
                .toolVaultCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InventoryValueCard(title: "Purchase Price", value: tool.purchasePrice.gbpFormatted, icon: "creditcard.fill", tint: ToolVaultTheme.steelBlue)
                    InventoryValueCard(title: "Estimated Resale", value: tool.estimatedResaleValue.gbpFormatted, icon: "chart.line.uptrend.xyaxis", tint: ToolVaultTheme.positive)
                    InventoryValueCard(title: "Depreciation", value: tool.depreciationAmount.gbpFormatted, icon: "arrow.down.forward.circle.fill", tint: ToolVaultTheme.warning)
                    InventoryValueCard(title: "Maintenance Logs", value: "\(maintenanceRecords.count)", icon: "wrench.fill", tint: ToolVaultTheme.accentOrange)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Asset details")
                    InfoRow(title: "Category", value: tool.category.rawValue)
                    InfoRow(title: "Serial number", value: tool.serialNumber.isEmpty ? "Not recorded" : tool.serialNumber)
                    InfoRow(title: "Storage location", value: tool.storageLocation.isEmpty ? "Not recorded" : tool.storageLocation)
                    InfoRow(title: "Assigned worker", value: tool.assignedUser.isEmpty ? "Unassigned" : tool.assignedUser)
                    InfoRow(title: "Purchase date", value: tool.purchaseDate.toolVaultShortDate)
                    InfoRow(title: "Notes", value: tool.notes.isEmpty ? "No notes" : tool.notes)
                }
                .toolVaultCard()

                VStack(spacing: 10) {
                    NavigationLink { MaintenanceTrackerView(focusedTool: tool) } label: {
                        DetailActionRow(title: "Maintenance history", subtitle: "\(maintenanceRecords.count) records", icon: "wrench.and.screwdriver.fill")
                    }
                    NavigationLink { ResaleValueTrackerView(focusedTool: tool) } label: {
                        DetailActionRow(title: "Value history", subtitle: "\(valueHistory.count) estimates", icon: "sterlingsign.arrow.circlepath")
                    }
                    NavigationLink { TeamAssignmentView(focusedTool: tool) } label: {
                        DetailActionRow(title: "Team assignment", subtitle: assignments.first?.assignedUser ?? "No active assignment", icon: "person.2.fill")
                    }
                    NavigationLink { TheftProtectionView(focusedTool: tool) } label: {
                        DetailActionRow(title: "Theft status", subtitle: theftReports.first?.status.rawValue ?? "No missing report", icon: "lock.shield.fill")
                    }
                }
                .buttonStyle(.plain)

                DisclaimerBox()
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Tool Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ToolVaultTheme.mutedText)
                .frame(width: 132, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailActionRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(ToolVaultTheme.accentOrange)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ToolVaultTheme.mutedText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(ToolVaultTheme.mutedText)
        }
        .toolVaultCard()
    }
}
