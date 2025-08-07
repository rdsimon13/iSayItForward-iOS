import SwiftUI

struct SIFComposerView: View {
    @StateObject private var viewModel = SIFComposerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching existing app style
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Recipient Section
                        RecipientSectionView(viewModel: viewModel)
                        
                        // MARK: - Message Content Section
                        MessageContentSectionView(viewModel: viewModel)
                        
                        // MARK: - Attachments Section
                        AttachmentPickerView(attachments: $viewModel.attachments)
                        
                        // MARK: - Scheduling Section
                        SchedulingSectionView(viewModel: viewModel)
                        
                        // MARK: - Privacy Controls Section
                        PrivacyControlsSectionView(viewModel: viewModel)
                        
                        // MARK: - Send Button
                        SendButtonView(viewModel: viewModel)
                    }
                    .padding()
                }
            }
            .navigationTitle("Compose SIF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        // If successful send, dismiss the view
                        if viewModel.alertTitle.contains("Sent") || viewModel.alertTitle.contains("Scheduled") {
                            dismiss()
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
}

// MARK: - Recipient Section

struct RecipientSectionView: View {
    @ObservedObject var viewModel: SIFComposerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipients")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Recipient Mode", selection: $viewModel.recipientMode) {
                ForEach(RecipientMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .background(.white.opacity(0.3))
            .cornerRadius(8)
            
            switch viewModel.recipientMode {
            case .single:
                TextField("Recipient's Email", text: $viewModel.singleRecipient)
                    .textFieldStyle(PillTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
            case .multiple:
                TextField("Recipients (comma separated)", text: $viewModel.multipleRecipients)
                    .textFieldStyle(PillTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
            case .group:
                Picker("Select Group", selection: $viewModel.selectedGroup) {
                    ForEach(viewModel.availableGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.white.opacity(0.8))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Message Content Section

struct MessageContentSectionView: View {
    @ObservedObject var viewModel: SIFComposerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Content")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Subject", text: $viewModel.subject)
                .textFieldStyle(PillTextFieldStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $viewModel.message)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(.white.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Scheduling Section

struct SchedulingSectionView: View {
    @ObservedObject var viewModel: SIFComposerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Schedule for later", isOn: $viewModel.shouldSchedule)
                .tint(Color.brandYellow)
            
            if viewModel.shouldSchedule {
                DatePicker(
                    "Delivery Date & Time",
                    selection: $viewModel.scheduleDate,
                    in: Date()...
                )
                .datePickerStyle(.compact)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Privacy Controls Section

struct PrivacyControlsSectionView: View {
    @ObservedObject var viewModel: SIFComposerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Controls")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Private Message", isOn: $viewModel.isPrivate)
                    .tint(Color.brandYellow)
                
                Toggle("Allow Forwarding", isOn: $viewModel.allowForwarding)
                    .tint(Color.brandYellow)
                
                Toggle("Require Read Receipt", isOn: $viewModel.requireReadReceipt)
                    .tint(Color.brandYellow)
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Send Button Section

struct SendButtonView: View {
    @ObservedObject var viewModel: SIFComposerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(viewModel.shouldSchedule ? "Schedule SIF" : "Send SIF")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.canSendMessage)
            .opacity(viewModel.canSendMessage ? 1.0 : 0.6)
            
            Button("Clear Form") {
                viewModel.clearForm()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Sending...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.black.opacity(0.7))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

struct SIFComposerView_Previews: PreviewProvider {
    static var previews: some View {
        SIFComposerView()
    }
}