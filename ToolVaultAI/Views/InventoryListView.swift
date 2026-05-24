import SwiftData
import SwiftUI

struct InventoryListView: View {
    @Query(sort: \ToolItem.createdAt, order: .reverse) private var tools: [ToolItem]
    @State private var searchText = ""
    @State private var selectedCategory: ToolCategory?
    @State private var showAddTool = false

    private var filteredTools: [ToolItem] {
        tools.filter { tool in
            let matchesSearch = searchText.isEmpty
                || tool.toolName.localizedCaseInsensitiveContains(searchText)
                || tool.brand.localizedCaseInsensitiveContains(searchText)
                || tool.model.localizedCaseInsensitiveContains(searchText)
                || tool.serialNumber.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || tool.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ToolVaultHeader("Inventory", subtitle: "\(tools.count) tracked tools across jobsites, vehicles, and storage.")

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(ToolVaultTheme.mutedText)
                        TextField("Search tools, brands, models, serials", text: $searchText)
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(12)
                    .background(ToolVaultTheme.elevatedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(ToolCategory.allCases) { category in
                                categoryChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .toolVaultCard()

                if filteredTools.isEmpty {
                    EmptyStateView(icon: "shippingbox", title: "No matching tools", message: "Add tools or adjust your filters to build the working inventory.", actionTitle: "Add Tool") {
                        showAddTool = true
                    }
                } else {
                    ForEach(filteredTools) { tool in
                        NavigationLink {
                            ToolDetailView(tool: tool)
                        } label: {
                            ToolCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .toolVaultScreenBackground()
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTool = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .foregroundStyle(ToolVaultTheme.accentOrange)
                .accessibilityLabel("Add tool")
            }
        }
        .sheet(isPresented: $showAddTool) {
            NavigationStack { ToolFormView() }
        }
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .black.opacity(0.82) : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? ToolVaultTheme.accentOrange : ToolVaultTheme.surfaceLight)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
