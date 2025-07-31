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
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    // Form fields
    @State private var recipientMode: RecipientMode = .single
    @State private var singleRecipient: String = ""
    @State private var multipleRecipients: String = ""
    @State private var selectedGroup: String = "Team" // Default value

    @State private var subject: String = ""
    @State private var message: String = ""

    // E-signature support
    @State private var requiresSignature = false
    @State private var signatureInstructions = ""

    // Scheduling
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingTierSelection = false

    // Placeholder data for the group picker
    let groups = ["Team", "Family", "Friends"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Usage warning if applicable
                        if let user = subscriptionManager.currentUser {
                            UsageLimitWarning(
                                currentUsage: 5, // In a real app, track actual usage
                                limit: user.effectiveTier.maxSIFsPerMonth,
                                title: "Monthly SIFs",
                                upgradeAction: {
                                    showingTierSelection = true
                                }
                            )
                        }
                        
                        // Ad banner (if applicable)
                        AdBannerView(subscriptionManager: subscriptionManager)
                        
                        // Recipient mode selection
                        ModernCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Send To")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.neutralGray800)
                                
                                Picker("Recipient Mode", selection: $recipientMode) {
                                    ForEach(RecipientMode.allCases, id: \.self) {
                                        Text($0.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                // Recipient input based on mode
                                switch recipientMode {
                                case .single:
                                    TextField("Recipient's Email", text: $singleRecipient)
                                        .textFieldStyle(ModernTextFieldStyle(iconName: "envelope.fill"))
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        
                                case .multiple:
                                    TextField("Recipients (comma separated)", text: $multipleRecipients)
                                        .textFieldStyle(ModernTextFieldStyle(iconName: "person.2.fill"))
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        
                                case .group:
                                    Picker("Select Group", selection: $selectedGroup) {
                                        ForEach(groups, id: \.self) { group in
                                            Text(group).tag(group)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(20)
                        }

                        // Message content
                        ModernCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Message Content")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.neutralGray800)

                                TextField("Subject", text: $subject)
                                    .textFieldStyle(ModernTextFieldStyle(iconName: "text.alignleft"))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Message")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.neutralGray600)
                                    
                                    TextEditor(text: $message)
                                        .frame(height: 120)
                                        .padding(12)
                                        .background(Color.neutralGray50)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.neutralGray200, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(20)
                        }

                        // E-signature section (feature gated)
                        ModernCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("E-Signature")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.neutralGray800)
                                    
                                    TierRequirementBadge(requiredTier: .premium)
                                    
                                    Spacer()
                                }
                                
                                if subscriptionManager.canAccessFeature(requiredTier: .premium) {
                                    Toggle("Require signature", isOn: $requiresSignature)
                                        .tint(.brandBlue)
                                    
                                    if requiresSignature {
                                        TextField("Signature instructions (optional)", text: $signatureInstructions)
                                            .textFieldStyle(ModernTextFieldStyle(iconName: "signature"))
                                    }
                                } else {
                                    UpgradePromptView(
                                        requiredTier: .premium,
                                        upgradeAction: {
                                            showingTierSelection = true
                                        }
                                    )
                                }
                            }
                            .padding(20)
                        }

                        // Scheduling section
                        ModernCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Delivery Options")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.neutralGray800)

                                Toggle("Schedule for later", isOn: $shouldSchedule)
                                    .tint(.brandBlue)

                                if shouldSchedule {
                                    DatePicker("Pick Date & Time", selection: $scheduleDate, in: Date()...)
                                        .datePickerStyle(.compact)
                                        .padding(.top, 8)
                                }
                            }
                            .padding(20)
                        }

                        // Send button
                        Button(action: saveSIF) {
                            HStack {
                                Image(systemName: shouldSchedule ? "clock.fill" : "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(shouldSchedule ? "Schedule SIF" : "Send SIF")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .buttonStyle(ModernPrimaryButtonStyle(
                            isEnabled: canSendSIF,
                            gradient: Color.primaryGradient
                        ))
                        .disabled(!canSendSIF)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create SIF")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingTierSelection) {
            TierSelectionView(isUpgradeFlow: true)
                .environmentObject(subscriptionManager)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                Task {
                    await subscriptionManager.fetchUserData(uid: uid)
                }
            }
        }
    }
    
    private var canSendSIF: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasValidRecipients
    }
    
    private var hasValidRecipients: Bool {
        switch recipientMode {
        case .single:
            return !singleRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .multiple:
            return !multipleRecipients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .group:
            return true // Group is always valid from picker
        }
    }

    // MARK: - Firestore Logic
    func saveSIF() {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be logged in to send a SIF.")
            return
        }

        // Check if user can create more SIFs
        guard subscriptionManager.canCreateSIF() else {
            showAlert(title: "Limit Reached", message: "You've reached your monthly SIF limit. Upgrade to send more.")
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
            scheduledDate: shouldSchedule ? scheduleDate : Date()
        )

        let db = Firestore.firestore()
        do {
            try db.collection("sifs").addDocument(from: newSif)
            showAlert(title: "Success!", message: shouldSchedule ? "Your SIF has been scheduled for delivery." : "Your SIF has been sent!")
            clearForm()
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
    }
    
    private func clearForm() {
        subject = ""
        message = ""
        singleRecipient = ""
        multipleRecipients = ""
        requiresSignature = false
        signatureInstructions = ""
        shouldSchedule = false
        scheduleDate = Date()
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
