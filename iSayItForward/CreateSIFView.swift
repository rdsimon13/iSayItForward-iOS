import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// This defines the different recipient modes.
// It must be defined outside the main View struct.
enum RecipientMode: String, CaseIterable {
    case single = "Single"
    case multiple = "Multiple"
    case group = "Group"
}

struct CreateSIFView: View {
    // MARK: - State Variables
    
    // Form fields
    @State private var recipientMode: RecipientMode = .single
    @State private var singleRecipient: String = ""
    @State private var multipleRecipients: String = ""
    @State private var selectedGroup: String = "Team" // Default value

    @State private var subject: String = ""
    @State private var message: String = ""
    
    // Categories and Tags
    @State private var selectedCategories: [Category] = []
    @State private var selectedTags: [String] = []

    // Scheduling
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Placeholder data for the group picker
    let groups = ["Team", "Family", "Friends"]

    var body: some View {
        // Use a NavigationStack to provide a title bar
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        Picker("Recipient Mode", selection: $recipientMode) {
                            ForEach(RecipientMode.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(.white.opacity(0.3))
                        .cornerRadius(8)

                        // Input fields for recipients, subject, and message
                        switch recipientMode {
                        case .single:
                            TextField("Recipient's Email", text: $singleRecipient)
                                .textFieldStyle(PillTextFieldStyle())
                        case .multiple:
                            TextField("Recipients (comma separated)", text: $multipleRecipients)
                                .textFieldStyle(PillTextFieldStyle())
                        case .group:
                            Picker("Select Group", selection: $selectedGroup) {
                                ForEach(groups, id: \.self) { Text($0) }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.white.opacity(0.8))
                            .clipShape(Capsule())
                        }

                        TextField("Subject", text: $subject)
                            .textFieldStyle(PillTextFieldStyle())

                        TextEditor(text: $message)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(8)
                            .background(.white.opacity(0.8))
                            .cornerRadius(20)

                        // Category Selection
                        CategorySelectionSection(
                            selectedCategories: $selectedCategories,
                            onCategoriesChanged: { categories in
                                selectedCategories = categories
                            }
                        )
                        
                        // Tag Selection
                        TagSelectionSection(
                            selectedTags: $selectedTags,
                            content: message,
                            category: selectedCategories.first,
                            onTagsChanged: { tags in
                                selectedTags = tags
                            }
                        )

                        // Scheduling UI
                        Toggle("Schedule for later", isOn: $shouldSchedule)
                            .tint(Color.brandYellow)
                            .padding()
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        if shouldSchedule {
                            DatePicker("Pick Date & Time", selection: $scheduleDate)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(.white.opacity(0.85))
                                .cornerRadius(16)
                        }
                        
                        Spacer()

                        // Send Button
                        Button("Send SIF") {
                            saveSIF()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle("Create a SIF")
                .navigationBarTitleDisplayMode(.inline) // Smaller title style
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Firestore Logic
    func saveSIF() {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be logged in to send a SIF.")
            return
        }

        var recipientList: [String]
        switch recipientMode {
        case .single:
            guard !singleRecipient.isEmpty else {
                showAlert(title: "Missing Information", message: "Please enter a recipient.")
                return
            }
            recipientList = [singleRecipient]
        case .multiple:
            guard !multipleRecipients.isEmpty else {
                showAlert(title: "Missing Information", message: "Please enter recipients.")
                return
            }
            recipientList = multipleRecipients.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        case .group:
            recipientList = [selectedGroup]
        }

        let newSif = SIFItem(
            authorUid: authorUid,
            recipients: recipientList,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: shouldSchedule ? scheduleDate : Date(),
            categoryIds: selectedCategories.compactMap { $0.id },
            tags: selectedTags
        )

        let db = Firestore.firestore()
        do {
            // The 'from' parameter requires SIFItem to conform to Codable
            try db.collection("sifs").addDocument(from: newSif)
            showAlert(title: "Success!", message: "Your SIF has been saved and is scheduled for delivery.")
            // You can add code here to clear the form fields if desired
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
    }
    
    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}

struct CreateSIFView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSIFView()
    }
}

// MARK: - Category Selection Section
struct CategorySelectionSection: View {
    @Binding var selectedCategories: [Category]
    let onCategoriesChanged: ([Category]) -> Void
    @State private var showingCategorySelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingCategorySelection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandYellow)
                }
            }
            
            if selectedCategories.isEmpty {
                Button {
                    showingCategorySelection = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.brandYellow)
                        Text("Add categories to organize your message")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(.white.opacity(0.6))
                    .cornerRadius(12)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedCategories, id: \.id) { category in
                            CategoryChip(
                                category: category,
                                onRemove: {
                                    removeCategory(category)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(16)
        .sheet(isPresented: $showingCategorySelection) {
            CategorySelectionSheet(
                selectedCategories: selectedCategories,
                onSelectionChanged: { categories in
                    selectedCategories = categories
                    onCategoriesChanged(categories)
                }
            )
        }
    }
    
    private func removeCategory(_ category: Category) {
        selectedCategories.removeAll { $0.id == category.id }
        onCategoriesChanged(selectedCategories)
    }
}

// MARK: - Tag Selection Section
struct TagSelectionSection: View {
    @Binding var selectedTags: [String]
    let content: String
    let category: Category?
    let onTagsChanged: ([String]) -> Void
    @State private var showingTagSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingTagSelection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.brandYellow)
                }
            }
            
            if selectedTags.isEmpty {
                Button {
                    showingTagSelection = true
                } label: {
                    HStack {
                        Image(systemName: "tag.circle")
                            .foregroundColor(.brandYellow)
                        Text("Add tags to make your message discoverable")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(.white.opacity(0.6))
                    .cornerRadius(12)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                onRemove: {
                                    removeTag(tag)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(16)
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionSheet(
                selectedTags: selectedTags,
                content: content,
                category: category,
                onTagsChanged: { tags in
                    selectedTags = tags
                    onTagsChanged(tags)
                }
            )
        }
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
        onTagsChanged(selectedTags)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: Category
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.caption2)
                .foregroundColor(CategoryUtilities.hexToColor(category.colorHex))
            
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CategoryUtilities.hexToColor(category.colorHex))
        )
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("#\(tag)")
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.brandYellow)
        )
    }
}

// MARK: - Category Selection Sheet
struct CategorySelectionSheet: View {
    let selectedCategories: [Category]
    let onSelectionChanged: ([Category]) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CategorySelectionViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                CategoryListView { category in
                    viewModel.toggleCategorySelection(category)
                }
            }
            .navigationTitle("Select Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelectionChanged(viewModel.selectedCategories)
                        dismiss()
                    }
                    .disabled(viewModel.selectedCategories.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel.setSelectionMode(.multiple, maxSelections: 3)
            viewModel.prepopulateSelection(with: selectedCategories)
        }
    }
}

// MARK: - Tag Selection Sheet
struct TagSelectionSheet: View {
    let selectedTags: [String]
    let content: String
    let category: Category?
    let onTagsChanged: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TagSelectionView { tags in
                    // Live update as tags change
                }
                .onAppear {
                    // Set initial tags and context
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Get tags from TagSelectionView and call onTagsChanged
                        onTagsChanged(selectedTags) // This would be updated to get actual selected tags
                        dismiss()
                    }
                }
            }
        }
    }
}
