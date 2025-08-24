import SwiftUI

struct SIFDetailView: View {
    let sif: SIFItem
    @StateObject private var deliveryService = SIFDeliveryService.shared
    @StateObject private var managerService = SIFManagerService.shared
    @StateObject private var qrCodeService = QRCodeService.shared
    @State private var showingQRCode = false
    @State private var showingCancelAlert = false
    @State private var showingExtendAlert = false
    @State private var newExpirationDate = Date()
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Status and Actions Header
                    VStack(spacing: 16) {
                        HStack {
                            DeliveryStatusBadge(status: sif.deliveryStatus)
                            Spacer()
                            
                            if sif.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if sif.deliveryStatus == .scheduled {
                                Button("Cancel SIF") {
                                    showingCancelAlert = true
                                }
                                .buttonStyle(SecondaryActionButtonStyle())
                            }
                            
                            if sif.expirationDate != nil && sif.canExtendExpiration {
                                Button("Extend") {
                                    newExpirationDate = sif.expirationDate?.addingTimeInterval(86400 * 7) ?? Date().addingTimeInterval(86400 * 7)
                                    showingExtendAlert = true
                                }
                                .buttonStyle(SecondaryActionButtonStyle())
                            }
                            
                            Button("QR Code") {
                                showingQRCode = true
                            }
                            .buttonStyle(PrimaryActionButtonStyle())
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Progress Bar for Active Deliveries
                    if deliveryService.activeDeliveries.contains(sif.id ?? "") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Delivery Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ProgressView(value: deliveryService.getProgress(for: sif.id ?? ""))
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("\(Int(deliveryService.getProgress(for: sif.id ?? "") * 100))% Complete")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Detail Card for Key Information
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "person.2.fill", title: "Recipients", value: sif.recipients.joined(separator: ", "))
                        Divider()
                        DetailRow(icon: "calendar", title: "Scheduled For", value: sif.scheduledDate.formatted(date: .long, time: .shortened))
                        Divider()
                        DetailRow(icon: "paperplane.fill", title: "Subject", value: sif.subject)
                        
                        if let deliveredDate = sif.deliveredDate {
                            Divider()
                            DetailRow(icon: "checkmark.circle", title: "Delivered", value: deliveredDate.formatted(date: .long, time: .shortened))
                        }
                        
                        if let expirationDate = sif.expirationDate {
                            Divider()
                            DetailRow(icon: "hourglass", title: "Expires", value: expirationDate.formatted(date: .long, time: .shortened))
                        }
                        
                        if sif.retryCount > 0 {
                            Divider()
                            DetailRow(icon: "arrow.clockwise", title: "Retry Attempts", value: "\(sif.retryCount)")
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Card for the Message Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(sif.message)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Attachments Section
                    if !sif.attachmentURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments (\(sif.attachmentURLs.count))")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(Array(sif.attachmentURLs.enumerated()), id: \.offset) { index, url in
                                    AttachmentCard(
                                        url: url,
                                        type: index < sif.attachmentTypes.count ? sif.attachmentTypes[index] : "unknown",
                                        size: index < sif.attachmentSizes.count ? sif.attachmentSizes[index] : 0
                                    )
                                }
                            }
                            
                            if sif.totalAttachmentSize > 0 {
                                Text("Total size: \(ByteCountFormatter.string(fromByteCount: sif.totalAttachmentSize, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    // Tags Section
                    if !sif.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(sif.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.2))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SIF Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(sif.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                            Task {
                                try? await managerService.toggleFavorite(sifId: sif.id ?? "")
                            }
                        }
                        
                        Button("Show QR Code") {
                            showingQRCode = true
                        }
                        
                        if let shareableURL = URL(string: sif.shareableLink ?? "") {
                            ShareLink("Share", item: shareableURL)
                        }
                        
                        Button(sif.isArchived ? "Unarchive" : "Archive") {
                            Task {
                                try? await managerService.toggleArchive(sifId: sif.id ?? "")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .foregroundColor(Color.brandDarkBlue)
        .sheet(isPresented: $showingQRCode) {
            QRCodeDisplayView(sif: sif)
        }
        .alert("Cancel SIF", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Cancel", role: .destructive) {
                Task {
                    try? await deliveryService.cancelSIF(sifId: sif.id ?? "")
                }
            }
        } message: {
            Text("Are you sure you want to cancel this scheduled SIF? This action cannot be undone.")
        }
        .alert("Extend Expiration", isPresented: $showingExtendAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Extend") {
                Task {
                    try? await deliveryService.extendSIFExpiration(sifId: sif.id ?? "", newExpirationDate: newExpirationDate)
                }
            }
        } message: {
            Text("Extend the expiration date to \(newExpirationDate.formatted(date: .abbreviated, time: .shortened))?")
        }
    }
}

// Helper view for a consistent row style in the detail card
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.body.weight(.semibold))
        }
    }
}

// Flow Layout for tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

struct FlowResult {
    let bounds: CGSize
    let frames: [CGRect]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        self.frames = frames
        self.bounds = CGSize(width: maxWidth, height: currentY + lineHeight)
    }
}

// Preview requires a sample SIFItem to work
struct SIFDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SIFDetailView(sif: SIFItem(authorUid: "123", recipients: ["preview@example.com"], subject: "Preview Subject", message: "This is a longer preview message to see how the text wraps and the card expands.", createdDate: Date(), scheduledDate: Date()))
        }
    }
}
