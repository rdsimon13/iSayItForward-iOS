import SwiftUI
import AVFoundation

struct QRCodeScannerMainView: View {
    @StateObject private var qrCodeService = QRCodeService.shared
    @State private var showingScanner = false
    @State private var showingSIF = false
    @State private var scannedSIF: SIFItem?
    @State private var scanError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("QR Code Scanner")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Scan QR codes to access shared SIFs instantly")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Start Scanning") {
                    checkCameraPermission()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top)
                
                // Recent scanned SIFs
                if !qrCodeService.recentScans.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Scans")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(qrCodeService.recentScans) { scan in
                                    RecentScanCard(scan: scan) {
                                        handleScannedSIF(scan.sif)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Scanner")
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerSheet { code in
                    handleScannedCode(code)
                }
            }
            .sheet(isPresented: $showingSIF) {
                if let sif = scannedSIF {
                    ScannedSIFDetailView(sif: sif)
                }
            }
            .alert("Scan Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(scanError ?? "Unknown error occurred")
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingScanner = true
                    } else {
                        scanError = "Camera permission is required to scan QR codes"
                        showingError = true
                    }
                }
            }
        case .denied, .restricted:
            scanError = "Camera permission is required. Please enable it in Settings."
            showingError = true
        @unknown default:
            scanError = "Camera not available"
            showingError = true
        }
    }
    
    private func handleScannedCode(_ code: String) {
        Task {
            let result = await qrCodeService.processScannedCode(code)
            
            DispatchQueue.main.async {
                switch result {
                case .success(let sif):
                    handleScannedSIF(sif)
                case .error(let error):
                    scanError = error
                    showingError = true
                }
            }
        }
    }
    
    private func handleScannedSIF(_ sif: SIFItem) {
        scannedSIF = sif
        showingSIF = true
        
        // Add to recent scans
        qrCodeService.addToRecentScans(sif)
    }
}

struct QRCodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCodeScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            QRCodeScannerRepresentable { code in
                onCodeScanned(code)
                dismiss()
            }
            
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                Text("Position the QR code within the frame")
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding()
            }
        }
        .ignoresSafeArea()
    }
}

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
}

struct ScannedSIFDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let sif: SIFItem
    @State private var showingQRCode = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sif.subject)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            DeliveryStatusBadge(status: sif.deliveryStatus)
                            Spacer()
                            Text(sif.createdDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Message Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(sif.message)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    // Attachments
                    if !sif.attachmentURLs.isEmpty {
                        Divider()
                        
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
                        }
                    }
                    
                    // Metadata
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                        
                        MetadataRow(label: "From", value: sif.authorUid)
                        MetadataRow(label: "Recipients", value: sif.recipients.joined(separator: ", "))
                        MetadataRow(label: "Created", value: sif.createdDate.formatted(date: .abbreviated, time: .shortened))
                        
                        if let deliveredDate = sif.deliveredDate {
                            MetadataRow(label: "Delivered", value: deliveredDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        
                        if let expirationDate = sif.expirationDate {
                            MetadataRow(label: "Expires", value: expirationDate.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Scanned SIF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Show QR Code") {
                            showingQRCode = true
                        }
                        
                        if let shareableURL = URL(string: sif.shareableLink ?? "") {
                            ShareLink("Share", item: shareableURL)
                        }
                        
                        Button("Add to Favorites") {
                            Task {
                                try? await SIFManagerService.shared.toggleFavorite(sifId: sif.id ?? "")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeDisplayView(sif: sif)
        }
    }
}

struct AttachmentCard: View {
    let url: String
    let type: String
    let size: Int64
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForFileType(type))
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            Text(URL(string: url)?.lastPathComponent ?? "Attachment")
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture {
            if let attachmentURL = URL(string: url) {
                UIApplication.shared.open(attachmentURL)
            }
        }
    }
    
    private func iconForFileType(_ type: String) -> String {
        switch type.lowercased() {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif":
            return "photo"
        case "pdf":
            return "doc.text"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "tablecells"
        case "ppt", "pptx":
            return "play.rectangle"
        case "mp3", "wav", "aac", "flac", "m4a":
            return "waveform"
        case "mp4", "mov", "avi":
            return "video"
        case "zip", "rar", "7z":
            return "archivebox"
        default:
            return "doc"
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct QRCodeDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    let sif: SIFItem
    @StateObject private var qrCodeService = QRCodeService.shared
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let qrImage = qrCodeImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 8)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .overlay(
                            ProgressView()
                        )
                }
                
                VStack(spacing: 8) {
                    Text(sif.subject)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Scan this code to access the SIF")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Share QR Code") {
                    shareQRCode()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        Task {
            let image = await qrCodeService.generateStyledQRCode(for: sif, withLogo: true)
            DispatchQueue.main.async {
                qrCodeImage = image
            }
        }
    }
    
    private func shareQRCode() {
        guard let qrImage = qrCodeImage else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [qrImage],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

struct RecentScanCard: View {
    let scan: RecentScan
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scan.sif.subject)
                .font(.headline)
                .lineLimit(2)
            
            Text(scan.scannedDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            
            DeliveryStatusBadge(status: scan.sif.deliveryStatus)
        }
        .padding()
        .frame(width: 200)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

// Extension to QRCodeService for recent scans
extension QRCodeService {
    @Published var recentScans: [RecentScan] = []
    
    func addToRecentScans(_ sif: SIFItem) {
        let scan = RecentScan(sif: sif, scannedDate: Date())
        
        // Remove if already exists
        recentScans.removeAll { $0.sif.id == sif.id }
        
        // Add to beginning
        recentScans.insert(scan, at: 0)
        
        // Keep only last 10 scans
        if recentScans.count > 10 {
            recentScans = Array(recentScans.prefix(10))
        }
    }
}

struct RecentScan: Identifiable {
    let id = UUID()
    let sif: SIFItem
    let scannedDate: Date
}

struct QRCodeScannerMainView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerMainView()
    }
}