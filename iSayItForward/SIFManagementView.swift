import SwiftUI
import FirebaseAuth

struct SIFManagementView: View {
    @StateObject private var managerService = SIFManagerService.shared
    @StateObject private var deliveryService = SIFDeliveryService.shared
    @State private var selectedFolder: SIFFolder?
    @State private var searchText = ""
    @State private var showingSearchFilters = false
    @State private var searchFilters = SIFSearchFilters()
    @State private var sortOption: SIFSortOption = .dateCreated
    @State private var selectedSIFs: Set<String> = []
    @State private var showingBatchActions = false
    @State private var showingNewFolderSheet = false
    
    var filteredSIFs: [SIFItem] {
        let folderSIFs = selectedFolder?.id == "search" 
            ? managerService.searchResults 
            : managerService.getSIFsInFolder(selectedFolder?.id ?? "sent")
        
        return managerService.sortSIFs(folderSIFs, by: sortOption)
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selectedFolder) {
                Section("Folders") {
                    ForEach(managerService.folders) { folder in
                        FolderRowView(folder: folder, count: managerService.getSIFsInFolder(folder.id).count)
                            .tag(folder)
                    }
                    
                    Button("New Folder") {
                        showingNewFolderSheet = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("SIF Manager")
            
            // Main Content
            VStack {
                if let folder = selectedFolder {
                    SIFListView(
                        folder: folder,
                        sifs: filteredSIFs,
                        selectedSIFs: $selectedSIFs,
                        sortOption: $sortOption,
                        searchText: $searchText,
                        showingSearchFilters: $showingSearchFilters,
                        showingBatchActions: $showingBatchActions
                    )
                } else {
                    Text("Select a folder to view SIFs")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search SIFs...")
        .onChange(of: searchText) { _ in
            performSearch()
        }
        .onAppear {
            Task {
                await managerService.fetchSIFs()
                managerService.startListening()
            }
            
            if selectedFolder == nil {
                selectedFolder = managerService.folders.first { $0.id == "sent" }
            }
        }
        .onDisappear {
            managerService.removeAllListeners()
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheet()
        }
        .sheet(isPresented: $showingSearchFilters) {
            SearchFiltersSheet(filters: $searchFilters) {
                performSearch()
            }
        }
        .sheet(isPresented: $showingBatchActions) {
            BatchActionsSheet(selectedSIFs: selectedSIFs) { operation in
                Task {
                    try? await managerService.performBatchOperation(operation, on: Array(selectedSIFs))
                    selectedSIFs.removeAll()
                    showingBatchActions = false
                }
            }
        }
    }
    
    private func performSearch() {
        Task {
            await managerService.searchSIFs(query: searchText, filters: searchFilters)
            
            if !searchText.isEmpty {
                // Switch to search results
                let searchFolder = SIFFolder(id: "search", name: "Search Results", icon: "magnifyingglass", color: "blue")
                selectedFolder = searchFolder
            }
        }
    }
}

struct FolderRowView: View {
    let folder: SIFFolder
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: folder.icon)
                .foregroundColor(Color(folder.color))
                .frame(width: 20)
            
            Text(folder.name)
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

struct SIFListView: View {
    let folder: SIFFolder
    let sifs: [SIFItem]
    @Binding var selectedSIFs: Set<String>
    @Binding var sortOption: SIFSortOption
    @Binding var searchText: String
    @Binding var showingSearchFilters: Bool
    @Binding var showingBatchActions: Bool
    
    @State private var showingCancelAlert = false
    @State private var sifToCancel: SIFItem?
    
    var isSelectionMode: Bool {
        !selectedSIFs.isEmpty
    }
    
    var body: some View {
        VStack {
            // Toolbar
            HStack {
                Text(folder.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isSelectionMode {
                    Button("Cancel") {
                        selectedSIFs.removeAll()
                    }
                    
                    Button("Actions") {
                        showingBatchActions = true
                    }
                    .disabled(selectedSIFs.isEmpty)
                } else {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SIFSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    
                    if !searchText.isEmpty {
                        Button("Filters") {
                            showingSearchFilters = true
                        }
                    }
                }
            }
            .padding()
            
            // SIF List
            if sifs.isEmpty {
                EmptyStateView(folder: folder, searchText: searchText)
            } else {
                List {
                    ForEach(sifs) { sif in
                        SIFRowView(
                            sif: sif,
                            isSelected: selectedSIFs.contains(sif.id ?? ""),
                            isSelectionMode: isSelectionMode
                        ) {
                            toggleSelection(for: sif)
                        } onCancel: {
                            sifToCancel = sif
                            showingCancelAlert = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .alert("Cancel SIF", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Cancel", role: .destructive) {
                if let sif = sifToCancel, let sifId = sif.id {
                    Task {
                        try? await SIFDeliveryService.shared.cancelSIF(sifId: sifId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to cancel this scheduled SIF? This action cannot be undone.")
        }
    }
    
    private func toggleSelection(for sif: SIFItem) {
        guard let sifId = sif.id else { return }
        
        if selectedSIFs.contains(sifId) {
            selectedSIFs.remove(sifId)
        } else {
            selectedSIFs.insert(sifId)
        }
    }
}

struct SIFRowView: View {
    let sif: SIFItem
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var deliveryService = SIFDeliveryService.shared
    
    var body: some View {
        HStack {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .onTapGesture {
                        onTap()
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sif.subject)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    DeliveryStatusBadge(status: sif.deliveryStatus)
                }
                
                Text("To: \(sif.recipients.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(sif.createdDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !sif.attachmentURLs.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(sif.attachmentURLs.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if sif.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    if sif.deliveryStatus == .scheduled {
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                
                // Progress bar for active deliveries
                if deliveryService.activeDeliveries.contains(sif.id ?? "") {
                    ProgressView(value: deliveryService.getProgress(for: sif.id ?? ""))
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            .padding(.vertical, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onTap()
            } else {
                // Navigate to detail view
            }
        }
    }
}

struct DeliveryStatusBadge: View {
    let status: SIFDeliveryStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImageName)
            Text(status.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.2))
        .foregroundColor(backgroundColor)
        .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case .delivered:
            return .green
        case .failed, .cancelled, .expired:
            return .red
        case .pending, .scheduled:
            return .orange
        case .processing, .uploading:
            return .blue
        }
    }
}

struct EmptyStateView: View {
    let folder: SIFFolder
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: folder.icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(emptyMessage)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
    
    private var emptyMessage: String {
        if !searchText.isEmpty {
            return "No SIFs found matching '\(searchText)'"
        }
        
        switch folder.id {
        case "sent":
            return "You haven't sent any SIFs yet"
        case "received":
            return "You haven't received any SIFs yet"
        case "favorites":
            return "No favorite SIFs"
        case "archived":
            return "No archived SIFs"
        case "scheduled":
            return "No scheduled SIFs"
        default:
            return "This folder is empty"
        }
    }
}

struct NewFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    
    private let icons = ["folder", "folder.fill", "tray", "archivebox", "heart", "star", "tag", "bookmark"]
    private let colors = ["blue", "green", "red", "orange", "purple", "pink", "yellow", "gray"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor : Color.secondary.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? .primary : .clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            try? await SIFManagerService.shared.createCustomFolder(
                                name: folderName,
                                icon: selectedIcon,
                                color: selectedColor
                            )
                            dismiss()
                        }
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

struct SearchFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: SIFSearchFilters
    let onApply: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status") {
                    ForEach(SIFDeliveryStatus.allCases, id: \.self) { status in
                        Toggle(status.displayName, isOn: Binding(
                            get: { filters.statuses.contains(status) },
                            set: { isOn in
                                if isOn {
                                    filters.statuses.append(status)
                                } else {
                                    filters.statuses.removeAll { $0 == status }
                                }
                            }
                        ))
                    }
                }
                
                Section("Date Range") {
                    DatePicker("From", selection: Binding(
                        get: { filters.dateFrom ?? Date() },
                        set: { filters.dateFrom = $0 }
                    ), displayedComponents: .date)
                    
                    DatePicker("To", selection: Binding(
                        get: { filters.dateTo ?? Date() },
                        set: { filters.dateTo = $0 }
                    ), displayedComponents: .date)
                }
                
                Section("Other") {
                    Toggle("Has Attachments", isOn: $filters.hasAttachmentsOnly)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        filters = SIFSearchFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BatchActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selectedSIFs: Set<String>
    let onPerformAction: (SIFBatchOperation) -> Void
    
    @StateObject private var managerService = SIFManagerService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Actions") {
                    Button("Archive") {
                        onPerformAction(.archive)
                    }
                    
                    Button("Add to Favorites") {
                        onPerformAction(.favorite)
                    }
                    
                    Button("Remove from Favorites") {
                        onPerformAction(.unfavorite)
                    }
                }
                
                Section("Move to Folder") {
                    ForEach(managerService.folders) { folder in
                        Button(folder.name) {
                            onPerformAction(.moveToFolder(folder.id))
                        }
                    }
                }
                
                Section("Destructive Actions") {
                    Button("Delete", role: .destructive) {
                        onPerformAction(.delete)
                    }
                }
            }
            .navigationTitle("Batch Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SIFManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SIFManagementView()
    }
}