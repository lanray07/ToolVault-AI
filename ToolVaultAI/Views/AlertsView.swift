import SwiftData
import SwiftUI

struct AlertsView: View {
    @Query(sort: \ToolItem.toolName) private var tools: [ToolItem]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @Query(sort: \TheftReport.dateReported, order: .reverse) private var theftReports: [TheftReport]
    @Query(sort: \AssignmentRecord.assignedDate, order: .reverse) private var assignments: [AssignmentRecord]

    private var dueMaintenance: [MaintenanceRecord] {
        maintenanceRecords.filter { record in
            guard let nextDueDate = record.nextDueDate else { return false }
            return nextDueDate <= .now
        }
    }

    private var activeTheftReports: [TheftReport] {
        theftReports.filter { $0.status != .recovered }
    }

    private var overdueAssignments: [AssignmentRecord] {
        assignments.filter { record in
            record.status == .assigned && (Calendar.current.dateComponents([.day], from: record.assignedDate, to: .now).day ?? 0) >= 7
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Alerts", subtitle: "Maintenance due, missing tools, and overdue assignment placeholders.")

                if dueMaintenance.isEmpty && activeTheftReports.isEmpty && overdueAssignments.isEmpty {
                    EmptyStateView(icon: "bell.badge", title: "No active alerts", message: "Maintenance reminders, missing tool reports, and overdue returns will appear here.")
                }

                if !dueMaintenance.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Maintenance due")
                        ForEach(dueMaintenance) { record in
                            MaintenanceCard(record: record, toolName: toolName(for: record.toolId))
                        }
                    }
                }

                if !activeTheftReports.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Missing tools")
                        ForEach(activeTheftReports) { report in
                            TheftAlertCard(report: report, toolName: toolName(for: report.toolId))
                        }
                    }
                }

                if !overdueAssignments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Overdue returns")
                        ForEach(overdueAssignments) { record in
                            AssignmentCard(record: record, toolName: toolName(for: record.toolId))
                        }
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolName(for toolID: UUID) -> String {
        tools.first { $0.id == toolID }?.toolName ?? "Tool"
    }
}
