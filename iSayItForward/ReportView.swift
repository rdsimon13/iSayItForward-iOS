import SwiftUI

struct ReportView: View {
    let contentId: String
    let contentAuthorUid: String
    let onDismiss: () -> Void
    
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    
    @State private var selectedCategory: ReportCategory = .spam
    @State private var reason: String = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let maxReasonLength = 500
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Report Content")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("Help us maintain a safe community by reporting inappropriate content.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        
                        // Report Category Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Why are you reporting this content?")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            ForEach(ReportCategory.allCases, id: \.self) { category in
                                CategoryRow(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Additional Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Details (Optional)")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text("Please provide any additional context that would help us understand your report.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $reason)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            HStack {
                                Spacer()
                                Text("\(reason.count)/\(maxReasonLength)")
                                    .font(.caption)
                                    .foregroundColor(reason.count > maxReasonLength ? .red : .secondary)
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Submit Button
                        Button(action: submitReport) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "flag.fill")
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Report")
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .disabled(isSubmitting || reason.count > maxReasonLength)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Report Submitted", isPresented: $showingSuccessAlert) {
            Button("OK") {
                onDismiss()
            }
        } message: {
            Text("Thank you for helping us maintain a safe community. We'll review your report and take appropriate action.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitReport() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await contentSafetyManager.submitReport(
                    contentId: contentId,
                    contentAuthorUid: contentAuthorUid,
                    category: selectedCategory,
                    reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Category Row Component

private struct CategoryRow: View {
    let category: ReportCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? Color.brandDarkBlue : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(
            contentId: "preview-content-id",
            contentAuthorUid: "preview-author-uid",
            onDismiss: { }
        )
    }
}