import SwiftUI

// MARK: - Report Reason Model
enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment or Bullying"
    case inappropriateContent = "Inappropriate Content"
    case falseInformation = "False Information"
    case copyrightViolation = "Copyright Violation"
    case other = "Other"
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - Report Content View
struct ReportContentView: View {
    @Binding var isPresented: Bool
    @State private var selectedReason: ReportReason?
    @State private var showingDetails = false
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            // Semi-transparent dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
                .accessibilityLabel("Close report overlay")
                .accessibilityHint("Tap to dismiss the report screen")
            
            // Main content card
            VStack(spacing: 0) {
                if showingDetails {
                    reportDetailsView
                } else {
                    reportReasonsView
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .padding(.horizontal, 32)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
        }
    }
    
    // MARK: - Report Reasons List View
    private var reportReasonsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Report Content")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
                .accessibilityHint("Close the report screen")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Reasons list
            LazyVStack(spacing: 0) {
                ForEach(ReportReason.allCases, id: \.self) { reason in
                    ReportReasonRow(
                        reason: reason,
                        isSelected: selectedReason == reason
                    ) {
                        selectedReason = reason
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingDetails = true
                        }
                    }
                    
                    if reason != ReportReason.allCases.last {
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Report Details View
    private var reportDetailsView: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingDetails = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(Color.brandDarkBlue)
                }
                
                Text("Report Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Selected reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Report Reason")
                            .font(.headline)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        Text(selectedReason?.description ?? "")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Additional details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Details")
                            .font(.headline)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        Text("Please provide any additional context that might help us understand the issue.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 100)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Submit button
                    Button {
                        submitReport()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Report")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isSubmitting)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Submit Report
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            
            // In a real app, you would send this to your backend
            print("Report submitted:")
            print("Reason: \(reason.description)")
            print("Details: \(additionalDetails)")
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }
    }
}

// MARK: - Report Reason Row
private struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(reason.description)
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ReportContentView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GradientTheme.welcomeBackground.ignoresSafeArea()
            
            ReportContentView(isPresented: .constant(true))
        }
    }
}
