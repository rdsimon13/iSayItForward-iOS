import SwiftUI

/// Interface for composing responses to SIFs with signature integration
struct ResponseComposerView: View {
    let sifItem: SIFItem
    let onResponseSubmitted: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var responseManager = ResponseManager()
    @StateObject private var signatureService = SignatureService()
    
    @State private var responseText = ""
    @State private var selectedCategory: ResponseCategory = .other
    @State private var selectedPrivacy: PrivacyLevel = .public
    @State private var requiresSignature = false
    @State private var signatureImage: UIImage?
    @State private var showingSignaturePad = false
    @State private var showingCategoryPicker = false
    @State private var showingPrivacyPicker = false
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Character limits
    private let maxCharacters = 5000
    private let minCharacters = 10
    
    var characterCount: Int {
        responseText.count
    }
    
    var isValidResponse: Bool {
        characterCount >= minCharacters && characterCount <= maxCharacters
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Original SIF context
                    originalSIFCard
                    
                    // Response composition section
                    responseCompositionSection
                    
                    // Category selection
                    categorySelectionSection
                    
                    // Privacy settings
                    privacySettingsSection
                    
                    // Signature section
                    signatureSection
                    
                    // Submit button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Compose Response")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitResponse()
                    }
                    .disabled(!isValidResponse || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(
                onSignatureComplete: { image in
                    signatureImage = image
                    showingSignaturePad = false
                },
                onCancel: {
                    showingSignaturePad = false
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - UI Components
    
    private var originalSIFCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                
                Text("Responding to:")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(sifItem.subject)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(sifItem.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Text("Scheduled: \(formatDate(sifItem.scheduledDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var responseCompositionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Response")
                    .font(.headline)
                
                Spacer()
                
                Text("\(characterCount)/\(maxCharacters)")
                    .font(.caption)
                    .foregroundColor(characterCount > maxCharacters ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $responseText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(characterCount > maxCharacters ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                if responseText.isEmpty {
                    Text("Write your response here...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // Character count warning
            if characterCount < minCharacters {
                Text("Minimum \(minCharacters) characters required")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if characterCount > maxCharacters {
                Text("Response exceeds maximum length")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Auto-categorization suggestion
            if !responseText.isEmpty {
                let suggestedCategory = responseManager.suggestCategory(for: responseText)
                if suggestedCategory != selectedCategory {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                        
                        Text("Suggested category: \(suggestedCategory.displayName)")
                            .font(.caption)
                        
                        Button("Use") {
                            selectedCategory = suggestedCategory
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
            }
        }
    }
    
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Response Category")
                .font(.headline)
            
            Button(action: {
                showingCategoryPicker = true
            }) {
                HStack {
                    Image(systemName: selectedCategory.iconName)
                        .foregroundColor(.blue)
                    
                    Text(selectedCategory.displayName)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .actionSheet(isPresented: $showingCategoryPicker) {
                ActionSheet(
                    title: Text("Select Response Category"),
                    buttons: ResponseCategory.allCases.map { category in
                        .default(Text(category.displayName)) {
                            selectedCategory = category
                        }
                    } + [.cancel()]
                )
            }
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Privacy Settings")
                .font(.headline)
            
            Button(action: {
                showingPrivacyPicker = true
            }) {
                HStack {
                    Image(systemName: privacyIcon(for: selectedPrivacy))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading) {
                        Text(selectedPrivacy.displayName)
                            .foregroundColor(.primary)
                        
                        Text(selectedPrivacy.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .actionSheet(isPresented: $showingPrivacyPicker) {
                ActionSheet(
                    title: Text("Select Privacy Level"),
                    buttons: PrivacyLevel.allCases.map { privacy in
                        .default(Text("\(privacy.displayName) - \(privacy.description)")) {
                            selectedPrivacy = privacy
                        }
                    } + [.cancel()]
                )
            }
        }
    }
    
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Digital Signature")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Required", isOn: $requiresSignature)
                    .labelsHidden()
            }
            
            if requiresSignature {
                VStack(spacing: 10) {
                    if let image = signatureImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Signature Preview:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Spacer()
                                
                                VStack(spacing: 5) {
                                    Button("Edit") {
                                        showingSignaturePad = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    
                                    Button("Remove") {
                                        signatureImage = nil
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        Button(action: {
                            showingSignaturePad = true
                        }) {
                            HStack {
                                Image(systemName: "signature")
                                Text("Add Signature")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    Text("Adding a signature validates your response and adds authenticity.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: submitResponse) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Response")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidResponse && !isSubmitting ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!isValidResponse || isSubmitting)
    }
    
    // MARK: - Helper Methods
    
    private func submitResponse() {
        guard isValidResponse else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let _ = try await responseManager.createResponse(
                    to: sifItem.id ?? "",
                    responseText: responseText,
                    category: selectedCategory,
                    privacyLevel: selectedPrivacy,
                    requiresSignature: requiresSignature,
                    signatureImage: signatureImage
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onResponseSubmitted()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func privacyIcon(for privacy: PrivacyLevel) -> String {
        switch privacy {
        case .public:
            return "globe"
        case .private:
            return "lock"
        case .restricted:
            return "lock.shield"
        case .anonymous:
            return "person.fill.questionmark"
        }
    }
}

// MARK: - Preview
struct ResponseComposerView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSIF = SIFItem(
            authorUid: "user123",
            recipients: ["recipient1@example.com"],
            subject: "Sample SIF Subject",
            message: "This is a sample SIF message that the user is responding to. It contains some meaningful content that would prompt a response.",
            createdDate: Date(),
            scheduledDate: Date().addingTimeInterval(3600)
        )
        
        ResponseComposerView(
            sifItem: sampleSIF,
            onResponseSubmitted: {
                print("Response submitted")
            },
            onCancel: {
                print("Response cancelled")
            }
        )
    }
}