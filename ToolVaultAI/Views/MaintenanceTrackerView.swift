import SwiftData
import SwiftUI

struct MaintenanceTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notifications: NotificationService

    let focusedTool: ToolItem?

    @Query(sort: \ToolItem.toolName) private var tools: [ToolItem]
    @Query(sort: \MaintenanceRecord.maintenanceDate, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]

    @State private var selectedToolID: UUID?
    @State private var maintenanceType: MaintenanceType = .servicing
    @State private var maintenanceDate = Date()
    @State private var costText = ""
    @State private var notes = ""
    @State private var recurrence: MaintenanceRecurrence = .none
    @State private var reminderEnabled = false
    @State private var errorMessage: String?

    init(focusedTool: ToolItem? = nil) {
        self.focusedTool = focusedTool
        _selectedToolID = State(initialValue: focusedTool?.id)
    }

    private var selectedTool: ToolItem? {
        tools.first { $0.id == selectedToolID } ?? focusedTool ?? tools.first
    }

    private var filteredRecords: [MaintenanceRecord] {
        guard let toolID = selectedTool?.id else { return maintenanceRecords }
        return maintenanceRecords.filter { $0.toolId == toolID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Maintenance", subtitle: "Track servicing, calibration, blades, batteries, inspections, cleaning, and costs.")

                if tools.isEmpty && focusedTool == nil {
                    EmptyStateView(icon: "wrench.and.screwdriver", title: "No tools available", message: "Add tools before creating maintenance logs.")
                } else {
                    maintenanceForm
                }

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Maintenance logs")
                    if filteredRecords.isEmpty {
                        EmptyStateView(icon: "calendar.badge.clock", title: "No maintenance records", message: "Add your first service, calibration, blade change, or inspection log.")
                    } else {
                        ForEach(filteredRecords) { record in
                            MaintenanceCard(record: record, toolName: toolName(for: record.toolId))
                        }
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedToolID == nil {
                selectedToolID = focusedTool?.id ?? tools.first?.id
            }
        }
    }

    private var maintenanceForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            picker("Tool", selection: $selectedToolID) {
                ForEach(tools) { tool in
                    Text(tool.toolName).tag(Optional(tool.id))
                }
                if let focusedTool, !tools.contains(where: { $0.id == focusedTool.id }) {
                    Text(focusedTool.toolName).tag(Optional(focusedTool.id))
                }
            }

            enumPicker("Maintenance type", selection: $maintenanceType, values: MaintenanceType.allCases)
            DatePicker("Maintenance date", selection: $maintenanceDate, displayedComponents: [.date, .hourAndMinute])
                .foregroundStyle(.white)
            SimpleTextField(title: "Cost", text: $costText, prompt: "0.00")
            SimpleTextField(title: "Notes", text: $notes, prompt: "Blade changed, calibrated, inspected")
            enumPicker("Recurring reminder", selection: $recurrence, values: MaintenanceRecurrence.allCases)
            Toggle("Enable reminder", isOn: $reminderEnabled)
                .tint(ToolVaultTheme.accentOrange)
                .foregroundStyle(.white)

            Button {
                addRecord()
            } label: {
                Label("Log Maintenance", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ToolVaultPrimaryButtonStyle())
        }
        .toolVaultCard()
    }

    private func addRecord() {
        guard let selectedTool else {
            errorMessage = "Select a tool before adding maintenance."
            return
        }
        let nextDueDate = nextDate(from: maintenanceDate, recurrence: recurrence)
        let record = MaintenanceRecord(
            toolId: selectedTool.id,
            maintenanceType: maintenanceType,
            maintenanceDate: maintenanceDate,
            cost: Double(costText) ?? 0,
            notes: notes,
            recurrence: recurrence,
            reminderEnabled: reminderEnabled,
            nextDueDate: nextDueDate
        )
        modelContext.insert(record)
        selectedTool.updatedAt = .now
        do {
            try modelContext.save()
            if reminderEnabled, let nextDueDate {
                Task {
                    await notifications.scheduleMaintenanceReminder(
                        toolName: selectedTool.toolName,
                        maintenanceType: maintenanceType,
                        date: nextDueDate,
                        recurrence: recurrence,
                        identifier: record.id.uuidString
                    )
                }
            }
            costText = ""
            notes = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nextDate(from date: Date, recurrence: MaintenanceRecurrence) -> Date? {
        switch recurrence {
        case .none:
            return nil
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return Calendar.current.date(byAdding: .month, value: 3, to: date)
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func toolName(for toolID: UUID) -> String {
        tools.first { $0.id == toolID }?.toolName ?? focusedTool?.toolName ?? "Tool"
    }

    private func picker<Content: View>(_ title: String, selection: Binding<UUID?>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            Picker(title, selection: selection, content: content)
                .pickerStyle(.menu)
                .tint(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ToolVaultTheme.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func enumPicker<T: Identifiable & Hashable & RawRepresentable>(_ title: String, selection: Binding<T>, values: [T]) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            Picker(title, selection: selection) {
                ForEach(values) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(ToolVaultTheme.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
