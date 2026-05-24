import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct AIToolScannerView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AIScannerViewModel()
    @State private var showCamera = false
    @State private var savedTool: ToolItem?
    @State private var showSavedAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("AI Tool Scanner", subtitle: "Mock AI is enabled by default and uses cautious, non-definitive language.")

                VStack(alignment: .leading, spacing: 14) {
                    if let data = viewModel.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        EmptyStateView(icon: "camera.viewfinder", title: "Add a tool photo", message: "Take or upload a clear photo for possible category, brand, wear, condition, and resale range estimates.")
                    }

                    HStack(spacing: 10) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Upload", systemImage: "photo.fill")
                        }
                        .buttonStyle(ToolVaultSecondaryButtonStyle())

                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                        }
                        .buttonStyle(ToolVaultSecondaryButtonStyle())
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(title: "Condition notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(ToolVaultTheme.elevatedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Button {
                        Task { await viewModel.analyze(aiService: aiService) }
                    } label: {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Run Mock AI Scan", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(ToolVaultPrimaryButtonStyle())
                }
                .toolVaultCard()

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error)
                }

                if let result = viewModel.result {
                    scannerResult(result)
                }

                DisclaimerBox()
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("AI Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { @MainActor in
                guard let newItem else { return }
                do {
                    viewModel.setUploadedPhoto(try await newItem.loadTransferable(type: Data.self))
                } catch {
                    viewModel.setUploadedPhoto(nil)
                }
                selectedPhotoItem = nil
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { data in
                viewModel.setCameraPhoto(data)
            }
        }
        .alert("Tool saved", isPresented: $showSavedAlert) {
            Button("OK") { savedTool = nil }
        } message: {
            Text(savedTool?.toolName ?? "")
        }
    }

    private func scannerResult(_ result: ToolAIAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("Scanner result")
            InfoLine(title: "Identified tool", value: result.identifiedTool)
            InfoLine(title: "Possible category", value: result.possibleCategory.rawValue)
            InfoLine(title: "Possible brand", value: result.possibleBrand)
            InfoLine(title: "Possible model", value: result.possibleModel)
            InfoLine(title: "Condition estimate", value: result.conditionEstimate.rawValue)
            InfoLine(title: "Estimated resale range", value: result.estimatedResaleRange)
            InfoLine(title: "Visible signs of wear", value: result.visibleWear)

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(title: "Insights")
                ForEach(result.insights, id: \.self) { insight in
                    Label(insight, systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(ToolVaultTheme.mutedText)
                }
            }

            Button {
                do {
                    savedTool = try viewModel.saveSuggestedTool(context: modelContext)
                    showSavedAlert = true
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            } label: {
                Label("Save as New Tool", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ToolVaultPrimaryButtonStyle())
        }
        .toolVaultCard()
    }
}
