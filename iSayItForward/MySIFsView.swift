import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MySIFsView: View {
    @StateObject private var managerService = SIFManagerService.shared
    @StateObject private var deliveryService = SIFDeliveryService.shared
    @State private var showingManagementView = false
    @State private var showingQRScanner = false

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    Color.mainAppGradient.ignoresSafeArea()

                    VStack {
                        if managerService.isLoading {
                            ProgressView("Loading SIFs...")
                                .foregroundColor(.white)
                        } else if managerService.sentSIFs.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "tray")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("You haven't sent any SIFs yet!")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Create your first SIF to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                        } else {
                            List {
                                // Quick Stats Section
                                Section {
                                    HStack {
                                        StatCard(
                                            title: "Sent",
                                            value: "\(managerService.sentSIFs.count)",
                                            icon: "paperplane.fill",
                                            color: .blue
                                        )
                                        
                                        StatCard(
                                            title: "Delivered",
                                            value: "\(managerService.sentSIFs.filter { $0.deliveryStatus == .delivered }.count)",
                                            icon: "checkmark.circle.fill",
                                            color: .green
                                        )
                                        
                                        StatCard(
                                            title: "Scheduled",
                                            value: "\(managerService.sentSIFs.filter { $0.deliveryStatus == .scheduled }.count)",
                                            icon: "calendar",
                                            color: .orange
                                        )
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                
                                // Recent SIFs
                                Section("Recent SIFs") {
                                    ForEach(Array(managerService.sentSIFs.prefix(5))) { sif in
                                        NavigationLink(destination: SIFDetailView(sif: sif)) {
                                            EnhancedSIFRowView(sif: sif)
                                        }
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.1))
                                
                                // Quick Actions
                                Section("Quick Actions") {
                                    NavigationLink(destination: SIFManagementView()) {
                                        ActionRowView(
                                            icon: "folder.fill",
                                            title: "Manage All SIFs",
                                            subtitle: "Organize, search, and batch edit",
                                            color: .blue
                                        )
                                    }
                                    
                                    Button {
                                        showingQRScanner = true
                                    } label: {
                                        ActionRowView(
                                            icon: "qrcode.viewfinder",
                                            title: "QR Code Scanner",
                                            subtitle: "Scan to view shared SIFs",
                                            color: .purple
                                        )
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.1))
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .navigationTitle("My SIFs")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button("Manage SIFs") {
                                    showingManagementView = true
                                }
                                
                                Button("QR Scanner") {
                                    showingQRScanner = true
                                }
                                
                                Button("Refresh") {
                                    Task {
                                        await managerService.fetchSIFs()
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            await managerService.fetchSIFs()
                            managerService.startListening()
                        }
                    }
                    .onDisappear {
                        managerService.removeAllListeners()
                    }
                }
            }
            .sheet(isPresented: $showingManagementView) {
                SIFManagementView()
            }
            .sheet(isPresented: $showingQRScanner) {
                QRCodeScannerMainView()
            }
        } else {
            Text("This feature requires iOS 16.0 or newer.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EnhancedSIFRowView: View {
    let sif: SIFItem
    @StateObject private var deliveryService = SIFDeliveryService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sif.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                DeliveryStatusBadge(status: sif.deliveryStatus)
            }
            
            Text("To: \(sif.recipients.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            HStack {
                Text(sif.createdDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                if !sif.attachmentURLs.isEmpty {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(sif.attachmentURLs.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                if sif.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                if sif.deliveryStatus == .scheduled {
                    Text("Scheduled for \(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Progress bar for active deliveries
            if deliveryService.activeDeliveries.contains(sif.id ?? "") {
                ProgressView(value: deliveryService.getProgress(for: sif.id ?? ""))
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .background(Color.white.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActionRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}
}

struct MySIFsView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                MySIFsView()
            }
        } else {
            Text("Preview not available below iOS 16.")
        }
    }
}
