import SwiftData
import SwiftUI

struct TeamAssignmentView: View {
    @Environment(\.modelContext) private var modelContext

    let focusedTool: ToolItem?

    @Query(sort: \ToolItem.toolName) private var tools: [ToolItem]
    @Query(sort: \AssignmentRecord.assignedDate, order: .reverse) private var assignments: [AssignmentRecord]

    @State private var selectedToolID: UUID?
    @State private var assignedUser = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    init(focusedTool: ToolItem? = nil) {
        self.focusedTool = focusedTool
        _selectedToolID = State(initialValue: focusedTool?.id)
    }

    private var selectedTool: ToolItem? {
        tools.first { $0.id == selectedToolID } ?? focusedTool ?? tools.first
    }

    private var visibleAssignments: [AssignmentRecord] {
        if let selectedTool {
            assignments.filter { $0.toolId == selectedTool.id }
        } else {
            assignments
        }
    }

    private var overdueAssignments: [AssignmentRecord] {
        assignments.filter { $0.status == .assigned && Calendar.current.dateComponents([.day], from: $0.assignedDate, to: .now).day ?? 0 >= 7 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Team Assignment", subtitle: "Assign tools to workers, track check-in/check-out placeholders, and surface overdue returns.")

                if tools.isEmpty && focusedTool == nil {
                    EmptyStateView(icon: "person.2.badge.gearshape", title: "No tools available", message: "Add tools before assigning them to workers.")
                } else {
                    assignmentForm
                }

                if !overdueAssignments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Overdue return alerts")
                        ForEach(overdueAssignments) { record in
                            AssignmentCard(record: record, toolName: toolName(for: record.toolId))
                        }
                    }
                }

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Assignment history")
                    if visibleAssignments.isEmpty {
                        EmptyStateView(icon: "person.crop.circle.badge.plus", title: "No assignments", message: "Assign a tool to a worker to start history.")
                    } else {
                        ForEach(visibleAssignments) { record in
                            VStack(spacing: 10) {
                                AssignmentCard(record: record, toolName: toolName(for: record.toolId))
                                if record.status == .assigned {
                                    Button {
                                        checkIn(record)
                                    } label: {
                                        Label("Check In", systemImage: "arrow.uturn.left.circle.fill")
                                    }
                                    .buttonStyle(ToolVaultSecondaryButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedToolID == nil {
                selectedToolID = focusedTool?.id ?? tools.first?.id
            }
        }
    }

    private var assignmentForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            picker("Tool", selection: $selectedToolID) {
                ForEach(tools) { tool in
                    Text(tool.toolName).tag(Optional(tool.id))
                }
                if let focusedTool, !tools.contains(where: { $0.id == focusedTool.id }) {
                    Text(focusedTool.toolName).tag(Optional(focusedTool.id))
                }
            }
            SimpleTextField(title: "Assigned worker", text: $assignedUser, prompt: "Worker name")
            SimpleTextField(title: "Notes", text: $notes, prompt: "Jobsite, vehicle, expected return")

            Button {
                assignTool()
            } label: {
                Label("Assign Tool", systemImage: "person.crop.circle.badge.plus")
            }
            .buttonStyle(ToolVaultPrimaryButtonStyle())
            .disabled(assignedUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .toolVaultCard()
    }

    private func assignTool() {
        guard let selectedTool else {
            errorMessage = "Select a tool before assigning it."
            return
        }
        let trimmedUser = assignedUser.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = AssignmentRecord(toolId: selectedTool.id, assignedUser: trimmedUser, notes: notes)
        selectedTool.assignedUser = trimmedUser
        selectedTool.updatedAt = .now
        modelContext.insert(record)
        do {
            try modelContext.save()
            assignedUser = ""
            notes = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkIn(_ record: AssignmentRecord) {
        record.returnedDate = .now
        record.status = .returned
        if let tool = tools.first(where: { $0.id == record.toolId }), tool.assignedUser == record.assignedUser {
            tool.assignedUser = ""
            tool.updatedAt = .now
        }
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
}
