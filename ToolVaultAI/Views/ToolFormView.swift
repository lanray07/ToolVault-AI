import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ToolFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ToolFormViewModel()
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolVaultHeader("Add Tool", subtitle: "Capture identity, condition, value, photos, and assignment details.")

                VStack(spacing: 14) {
                    VaultTextField(title: "Tool name", text: $viewModel.toolName, prompt: "Milwaukee M18 impact driver")
                    picker("Category", selection: $viewModel.category, values: ToolCategory.allCases)
                    VaultTextField(title: "Brand", text: $viewModel.brand, prompt: "Milwaukee")
                    VaultTextField(title: "Model", text: $viewModel.model, prompt: "M18 FID3")
                    VaultTextField(title: "Serial number", text: $viewModel.serialNumber, prompt: "Serial number")

                    DatePicker("Purchase date", selection: $viewModel.purchaseDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundStyle(.white)

                    VaultTextField(title: "Purchase price", text: $viewModel.purchasePriceText, prompt: "0.00", keyboardType: .decimalPad)
                    picker("Current condition", selection: $viewModel.condition, values: ToolCondition.allCases)
                    VaultTextField(title: "Estimated resale value", text: $viewModel.estimatedResaleValueText, prompt: "0.00", keyboardType: .decimalPad)
                    VaultTextField(title: "Storage location", text: $viewModel.storageLocation, prompt: "Van 2, Site A, lockup")
                    VaultTextField(title: "Assigned user", text: $viewModel.assignedUser, prompt: "Worker name")

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(title: "Notes")
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 110)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(ToolVaultTheme.elevatedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Toggle(isOn: $viewModel.receiptPlaceholder) {
                        Label("Receipt placeholder", systemImage: "receipt.fill")
                            .foregroundStyle(.white)
                    }
                    .tint(ToolVaultTheme.accentOrange)
                }
                .toolVaultCard()

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Photos")
                    HStack(spacing: 10) {
                        PhotosPicker(selection: $viewModel.selectedPhotoItems, maxSelectionCount: 8, matching: .images) {
                            Label("Upload Photos", systemImage: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(ToolVaultSecondaryButtonStyle())

                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ToolVaultSecondaryButtonStyle())
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    }

                    if viewModel.isLoadingPhotos {
                        ProgressView("Importing photos")
                            .tint(ToolVaultTheme.accentOrange)
                            .foregroundStyle(ToolVaultTheme.mutedText)
                    }

                    if !viewModel.photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(viewModel.photoData.enumerated()), id: \.offset) { _, data in
                                    PhotoThumbnail(data: data)
                                }
                            }
                        }
                    }
                }
                .toolVaultCard()

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error)
                }

                Button {
                    save()
                } label: {
                    Label("Save Tool", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(ToolVaultPrimaryButtonStyle())
                .disabled(!viewModel.canSave)
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Add Tool")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(ToolVaultTheme.accentOrange)
            }
        }
        .onChange(of: viewModel.selectedPhotoItems) { _, newItems in
            Task { await viewModel.loadPhotos(from: newItems) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { data in
                viewModel.addCameraPhoto(data)
            }
        }
    }

    private func save() {
        do {
            try viewModel.save(context: modelContext)
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func picker<T: Identifiable & Hashable & RawRepresentable>(_ title: String, selection: Binding<T>, values: [T]) -> some View where T.RawValue == String {
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

private struct VaultTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: title)
            TextField(prompt, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .background(ToolVaultTheme.elevatedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
