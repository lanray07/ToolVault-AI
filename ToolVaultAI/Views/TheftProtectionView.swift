import SwiftData
import SwiftUI

struct TheftProtectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.qrLabelService) private var qrLabelService
    @Environment(\.nfcTagService) private var nfcTagService

    let focusedTool: ToolItem?

    @Query(sort: \ToolItem.toolName) private var tools: [ToolItem]
    @Query(sort: \TheftReport.dateReported, order: .reverse) private var theftReports: [TheftReport]

    @State private var selectedToolID: UUID?
    @State private var lastKnownLocation = ""
    @State private var reportNotes = ""
    @State private var qrPayload: QRLabelPayload?
    @State private var nfcPayload: NFCTagPayload?
    @State private var sharePayload: SharePayload?
    @State private var errorMessage: String?

    init(focusedTool: ToolItem? = nil) {
        self.focusedTool = focusedTool
        _selectedToolID = State(initialValue: focusedTool?.id)
    }

    private var selectedTool: ToolItem? {
        tools.first { $0.id == selectedToolID } ?? focusedTool ?? tools.first
    }

    private var relevantReports: [TheftReport] {
        if let selectedTool {
            theftReports.filter { $0.toolId == selectedTool.id }
        } else {
            theftReports
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Theft Protection", subtitle: "Prepare missing-tool records, serial exports, QR labels, and NFC placeholder payloads.")

                if tools.isEmpty && focusedTool == nil {
                    EmptyStateView(icon: "lock.shield", title: "No tools to protect", message: "Add tools with serial numbers, photos, and locations before creating theft reports.")
                } else {
                    theftForm
                }

                if let qrPayload {
                    placeholderCard(title: "QR label placeholder", icon: "qrcode", lines: [
                        qrPayload.displayName,
                        qrPayload.serialNumber.isEmpty ? "No serial recorded" : qrPayload.serialNumber,
                        qrPayload.encodedPayload
                    ])
                }

                if let nfcPayload {
                    placeholderCard(title: "NFC tag placeholder", icon: "wave.3.right.circle.fill", lines: [
                        nfcPayload.displayName,
                        nfcPayload.payload,
                        nfcPayload.notes
                    ])
                }

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Missing tool reports")
                    if relevantReports.isEmpty {
                        EmptyStateView(icon: "exclamationmark.lock", title: "No missing reports", message: "Mark a tool missing to create a theft report draft.")
                    } else {
                        ForEach(relevantReports) { report in
                            TheftAlertCard(report: report, toolName: toolName(for: report.toolId))
                        }
                    }
                }

                DisclaimerBox()
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Theft")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedToolID == nil {
                selectedToolID = focusedTool?.id ?? tools.first?.id
            }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
    }

    private var theftForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            picker("Tool", selection: $selectedToolID) {
                ForEach(tools) { tool in
                    Text(tool.toolName).tag(Optional(tool.id))
                }
                if let focusedTool, !tools.contains(where: { $0.id == focusedTool.id }) {
                    Text(focusedTool.toolName).tag(Optional(focusedTool.id))
                }
            }

            SimpleTextField(title: "Last known location", text: $lastKnownLocation, prompt: "Van, jobsite, lockup, client address")
            SimpleTextField(title: "Report notes", text: $reportNotes, prompt: "When last seen, serial, accessories, markings")

            Button {
                markMissing(status: .missing)
            } label: {
                Label("Mark Tool Missing", systemImage: "exclamationmark.lock.fill")
            }
            .buttonStyle(ToolVaultPrimaryButtonStyle())

            HStack(spacing: 10) {
                Button {
                    generateQRPayload()
                } label: {
                    Label("QR Label", systemImage: "qrcode")
                }
                .buttonStyle(ToolVaultSecondaryButtonStyle())

                Button {
                    generateNFCPayload()
                } label: {
                    Label("NFC Tag", systemImage: "wave.3.right.circle.fill")
                }
                .buttonStyle(ToolVaultSecondaryButtonStyle())
            }

            HStack(spacing: 10) {
                Button {
                    exportSerials()
                } label: {
                    Label("Serial Export", systemImage: "list.clipboard.fill")
                }
                .buttonStyle(ToolVaultSecondaryButtonStyle())

                Button {
                    exportPoliceInsurancePlaceholder()
                } label: {
                    Label("Police/Insurance", systemImage: "doc.text.fill")
                }
                .buttonStyle(ToolVaultSecondaryButtonStyle())
            }
        }
        .toolVaultCard()
    }

    private func markMissing(status: TheftReportStatus) {
        guard let selectedTool else {
            errorMessage = "Select a tool before creating a report."
            return
        }
        selectedTool.currentCondition = .missing
        selectedTool.updatedAt = .now
        let report = TheftReport(
            toolId: selectedTool.id,
            reportNotes: reportNotes,
            lastKnownLocation: lastKnownLocation,
            status: status
        )
        modelContext.insert(report)
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func generateQRPayload() {
        guard let selectedTool else { return }
        qrPayload = qrLabelService.makeLabelPayload(for: selectedTool)
    }

    private func generateNFCPayload() {
        guard let selectedTool else { return }
        nfcPayload = nfcTagService.makeTagPayload(for: selectedTool)
    }

    private func exportSerials() {
        let csv = tools.map { "\($0.toolName),\($0.brand),\($0.model),\($0.serialNumber),\($0.storageLocation)" }
            .joined(separator: "\n")
        sharePayload = SharePayload(items: ["Tool Name,Brand,Model,Serial,Location\n\(csv)"])
    }

    private func exportPoliceInsurancePlaceholder() {
        guard let selectedTool else { return }
        let text = """
        ToolVault AI Missing Tool Export
        Tool: \(selectedTool.toolName)
        Brand: \(selectedTool.brand)
        Model: \(selectedTool.model)
        Serial: \(selectedTool.serialNumber)
        Last known location: \(lastKnownLocation)
        Notes: \(reportNotes)

        This export is a placeholder and is not an insurance valuation.
        """
        sharePayload = SharePayload(items: [text])
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

    private func placeholderCard(title: String, icon: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(ToolVaultTheme.mutedText)
                    .textSelection(.enabled)
            }
        }
        .toolVaultCard()
    }
}
