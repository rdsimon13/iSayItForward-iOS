import SwiftUI

struct CategoryListView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var showingCreateCategory = false
    @State private var selectedSortOption: CategorySortOption = .name
    
    // Optional closure for category selection
    let onCategorySelected: ((Category) -> Void)?
    
    init(onCategorySelected: ((Category) -> Void)? = nil) {
        self.onCategorySelected = onCategorySelected
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    searchAndFilterSection
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredCategories.isEmpty {
                        emptyStateView
                    } else {
                        categoryGridView
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateCategory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandYellow)
                    }
                }
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCategoryView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search categories...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.white.opacity(0.9))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Sort Options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CategorySortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: option.iconName)
                                Text(option.displayName)
                            }
                            .font(.caption)
                            .foregroundColor(viewModel.sortOption == option ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.sortOption == option ? Color.brandYellow : Color.white.opacity(0.7))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Category Grid View
    private var categoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.filteredCategories) { category in
                    CategoryCardView(category: category) {
                        handleCategorySelection(category)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading categories...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.brandYellow.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Categories Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.searchText.isEmpty ? 
                     "Create your first category to organize your messages" :
                     "No categories match your search")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                if viewModel.searchText.isEmpty {
                    showingCreateCategory = true
                } else {
                    viewModel.searchText = ""
                }
            } label: {
                Text(viewModel.searchText.isEmpty ? "Create Category" : "Clear Search")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.brandYellow)
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Grid Columns
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }
    
    // MARK: - Actions
    private func handleCategorySelection(_ category: Category) {
        viewModel.selectCategory(category)
        onCategorySelected?(category)
    }
}

// MARK: - Category Card View
struct CategoryCardView: View {
    let category: Category
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundColor(CategoryUtilities.hexToColor(category.colorHex))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(CategoryUtilities.hexToColor(category.colorHex).opacity(0.2))
                    )
                
                // Content
                VStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                
                // Statistics
                HStack(spacing: 12) {
                    StatBadge(
                        icon: "envelope.fill",
                        value: CategoryUtilities.formatUsageCount(category.messageCount),
                        color: .blue
                    )
                    
                    StatBadge(
                        icon: "person.2.fill",
                        value: CategoryUtilities.formatUsageCount(category.subscriberCount),
                        color: .green
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Badge View
struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Create Category View
struct CreateCategoryView: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = CategoryConstants.Defaults.categoryColor
    @State private var parentCategory: Category?
    
    private let availableIcons = [
        "folder.fill", "heart.fill", "star.fill", "flag.fill",
        "bookmark.fill", "tag.fill", "paperplane.fill", "gift.fill",
        "party.popper.fill", "hands.sparkles.fill", "megaphone.fill",
        "calendar", "clock.fill", "bell.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Category Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Appearance") {
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? Color.brandYellow : Color.gray.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(CategoryConstants.defaultCategoryColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(CategoryUtilities.hexToColor(color))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                
                Section("Organization") {
                    Picker("Parent Category", selection: $parentCategory) {
                        Text("None").tag(Category?.none)
                        ForEach(viewModel.categories.filter { $0.parentCategoryId == nil }) { category in
                            Text(category.displayName).tag(category as Category?)
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createCategory() {
        viewModel.createCategory(
            name: name,
            description: description,
            iconName: selectedIcon,
            colorHex: selectedColor,
            parentCategoryId: parentCategory?.id
        )
        dismiss()
    }
}

// MARK: - Preview
struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryListView()
    }
}