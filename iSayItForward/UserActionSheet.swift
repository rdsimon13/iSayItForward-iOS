import SwiftUI

struct UserActionSheet: View {
    let userId: String
    let userName: String
    @StateObject private var blockingService = BlockingService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingBlockAlert = false
    @State private var selectedBlockReason: BlockReason?
    @State private var showingReasonSheet = false
    @State private var isBlocking = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    private var isAlreadyBlocked: Bool {
        blockingService.isUserBlocked(userId)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User Info Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text(userName)
                        .font(.title2.weight(.semibold))
                }
                .padding(.top)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if isAlreadyBlocked {
                        Button(action: unblockUser) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Unblock User")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isBlocking)
                    } else {
                        Button(action: {
                            showingReasonSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.slash")
                                Text("Block User")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isBlocking)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("User Actions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                try? await blockingService.loadBlockedUsers()
            }
        }
        .sheet(isPresented: $showingReasonSheet) {
            BlockReasonSelectionView(
                userName: userName,
                onBlock: { reason in
                    selectedBlockReason = reason
                    blockUser()
                }
            )
        }
        .alert("Success", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func blockUser() {
        isBlocking = true
        
        Task {
            do {
                try await blockingService.blockUser(userId, reason: selectedBlockReason)
                await MainActor.run {
                    isBlocking = false
                    alertMessage = "\(userName) has been blocked successfully."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func unblockUser() {
        isBlocking = true
        
        Task {
            do {
                try await blockingService.unblockUser(userId)
                await MainActor.run {
                    isBlocking = false
                    alertMessage = "\(userName) has been unblocked successfully."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct BlockReasonSelectionView: View {
    let userName: String
    let onBlock: (BlockReason?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: BlockReason?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Why are you blocking \(userName)?")
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal)
                
                Text("This will prevent them from interacting with your content.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(BlockReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(selectedReason == reason ? Color.blue.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedReason == reason ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Option for no specific reason
                    Button(action: {
                        selectedReason = nil
                    }) {
                        HStack {
                            Text("Prefer not to say")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedReason == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedReason == nil ? Color.blue.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedReason == nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Block User") {
                    onBlock(selectedReason)
                    dismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.horizontal)
            }
            .navigationTitle("Block User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        UserActionSheet(userId: "sample-user-id", userName: "John Doe")
    }
}