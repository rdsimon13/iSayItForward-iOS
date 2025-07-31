import Foundation
import UIKit
import CoreImage
import AVFoundation
import SwiftUI

// Service responsible for QR code generation, scanning, and deep linking
class QRCodeService: NSObject, ObservableObject {
    static let shared = QRCodeService()
    
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var scanError: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupCameraSession()
    }
    
    // MARK: - QR Code Generation
    
    /// Generates a QR code image for a SIF
    func generateQRCode(for sif: SIFItem) -> UIImage? {
        guard let sifId = sif.id else { return nil }
        
        let qrData = createQRCodeData(for: sif)
        return generateQRCodeImage(from: qrData)
    }
    
    /// Generates QR code data containing SIF information
    private func createQRCodeData(for sif: SIFItem) -> String {
        let baseURL = "https://isayitforward.app/sif/"
        let qrData = QRCodeData(
            sifId: sif.id ?? "",
            type: "sif",
            url: "\(baseURL)\(sif.id ?? "")",
            subject: sif.subject,
            authorUid: sif.authorUid,
            createdDate: sif.createdDate.timeIntervalSince1970,
            expirationDate: sif.expirationDate?.timeIntervalSince1970
        )
        
        guard let jsonData = try? JSONEncoder().encode(qrData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "\(baseURL)\(sif.id ?? "")" // Fallback to simple URL
        }
        
        return jsonString
    }
    
    /// Generates QR code image from string data
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        // Set error correction level
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale up the image
        let scaleX = 300 / outputImage.extent.size.width
        let scaleY = 300 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generates a styled QR code with branding
    func generateStyledQRCode(for sif: SIFItem, withLogo: Bool = true) -> UIImage? {
        guard let qrImage = generateQRCode(for: sif) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw QR code
            qrImage.draw(in: CGRect(origin: .zero, size: size))
            
            // Add logo in center if requested
            if withLogo {
                let logoSize = CGSize(width: 60, height: 60)
                let logoRect = CGRect(
                    x: (size.width - logoSize.width) / 2,
                    y: (size.height - logoSize.height) / 2,
                    width: logoSize.width,
                    height: logoSize.height
                )
                
                // Draw logo background
                UIColor.white.setFill()
                context.fillEllipse(in: logoRect.insetBy(dx: -5, dy: -5))
                
                // Draw app icon or placeholder
                if let appIcon = UIImage(named: "AppIcon") {
                    appIcon.draw(in: logoRect)
                } else {
                    // Draw placeholder logo
                    UIColor.systemBlue.setFill()
                    context.fillEllipse(in: logoRect)
                }
            }
        }
    }
    
    // MARK: - QR Code Scanning
    
    /// Starts QR code scanning
    func startScanning() {
        guard !isScanning else { return }
        
        isScanning = true
        scanError = nil
        scannedCode = nil
        
        guard let captureSession = captureSession else {
            handleScanError("Camera not available")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    /// Stops QR code scanning
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
    }
    
    /// Sets up camera session for QR code scanning
    private func setupCameraSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            handleScanError("Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            handleScanError("Camera input error: \(error.localizedDescription)")
            return
        }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            handleScanError("Could not add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            handleScanError("Could not add metadata output")
            return
        }
    }
    
    /// Creates preview layer for camera view
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        return previewLayer
    }
    
    private func handleScanError(_ message: String) {
        DispatchQueue.main.async {
            self.scanError = message
            self.isScanning = false
        }
    }
    
    // MARK: - QR Code Data Processing
    
    /// Processes scanned QR code data
    func processScannedCode(_ code: String) async -> QRCodeResult {
        // First, try to parse as JSON (structured data)
        if let qrData = parseQRCodeData(code) {
            return await handleStructuredQRCode(qrData)
        }
        
        // Check if it's a URL
        if code.hasPrefix("https://isayitforward.app/") {
            return await handleURLQRCode(code)
        }
        
        // Unknown format
        return .error("Invalid QR code format")
    }
    
    private func parseQRCodeData(_ code: String) -> QRCodeData? {
        guard let data = code.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(QRCodeData.self, from: data)
    }
    
    private func handleStructuredQRCode(_ qrData: QRCodeData) async -> QRCodeResult {
        // Validate expiration
        if let expirationTimestamp = qrData.expirationDate {
            let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
            if expirationDate < Date() {
                return .error("This SIF has expired")
            }
        }
        
        // Fetch SIF data
        do {
            let sif = try await fetchSIF(id: qrData.sifId)
            return .success(sif)
        } catch {
            return .error("Failed to load SIF: \(error.localizedDescription)")
        }
    }
    
    private func handleURLQRCode(_ url: String) async -> QRCodeResult {
        // Extract SIF ID from URL
        let components = url.components(separatedBy: "/")
        guard let sifId = components.last, !sifId.isEmpty else {
            return .error("Invalid SIF URL")
        }
        
        do {
            let sif = try await fetchSIF(id: sifId)
            return .success(sif)
        } catch {
            return .error("Failed to load SIF from URL")
        }
    }
    
    private func fetchSIF(id: String) async throws -> SIFItem {
        let document = try await Firestore.firestore().collection("sifs").document(id).getDocument()
        
        guard document.exists else {
            throw QRCodeError.sifNotFound
        }
        
        guard let sif = try? document.data(as: SIFItem.self) else {
            throw QRCodeError.invalidSIFData
        }
        
        return sif
    }
    
    // MARK: - Deep Linking
    
    /// Handles deep link URLs from QR codes
    func handleDeepLink(_ url: URL) async -> DeepLinkResult {
        guard url.scheme == "isayitforward" || url.host == "isayitforward.app" else {
            return .unsupported
        }
        
        let pathComponents = url.pathComponents
        
        if pathComponents.contains("sif"), let sifId = pathComponents.last {
            do {
                let sif = try await fetchSIF(id: sifId)
                return .sif(sif)
            } catch {
                return .error("Failed to load SIF: \(error.localizedDescription)")
            }
        }
        
        if pathComponents.contains("share"), let sifId = pathComponents.last {
            do {
                let sif = try await fetchSIF(id: sifId)
                return .share(sif)
            } catch {
                return .error("Failed to load shared SIF: \(error.localizedDescription)")
            }
        }
        
        return .unsupported
    }
    
    /// Generates shareable URL for a SIF
    func generateShareableURL(for sif: SIFItem) -> URL? {
        guard let sifId = sif.id else { return nil }
        return URL(string: "https://isayitforward.app/share/\(sifId)")
    }
    
    /// Generates deep link URL for a SIF
    func generateDeepLinkURL(for sif: SIFItem) -> URL? {
        guard let sifId = sif.id else { return nil }
        return URL(string: "isayitforward://sif/\(sifId)")
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first else { return }
        
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
        
        guard let stringValue = readableObject.stringValue else { return }
        
        // Haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        scannedCode = stringValue
        stopScanning()
    }
}

// MARK: - Supporting Models

struct QRCodeData: Codable {
    let sifId: String
    let type: String
    let url: String
    let subject: String
    let authorUid: String
    let createdDate: TimeInterval
    let expirationDate: TimeInterval?
}

enum QRCodeResult {
    case success(SIFItem)
    case error(String)
}

enum DeepLinkResult {
    case sif(SIFItem)
    case share(SIFItem)
    case error(String)
    case unsupported
}

enum QRCodeError: LocalizedError {
    case sifNotFound
    case invalidSIFData
    case scanningNotSupported
    case cameraPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .sifNotFound:
            return "SIF not found"
        case .invalidSIFData:
            return "Invalid SIF data"
        case .scanningNotSupported:
            return "QR code scanning not supported on this device"
        case .cameraPermissionDenied:
            return "Camera permission is required for QR code scanning"
        }
    }
}

// MARK: - SwiftUI Integration

struct QRCodeScannerView: UIViewControllerRepresentable {
    @ObservedObject var qrCodeService: QRCodeService
    @Binding var isPresented: Bool
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.qrCodeService = qrCodeService
        controller.onCodeScanned = onCodeScanned
        controller.onDismiss = {
            isPresented = false
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
}

class QRCodeScannerViewController: UIViewController {
    var qrCodeService: QRCodeService?
    var onCodeScanned: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        qrCodeService?.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        qrCodeService?.stopScanning()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupCamera() {
        guard let previewLayer = qrCodeService?.createPreviewLayer() else { return }
        
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        
        // Add scanning overlay
        addScanningOverlay()
    }
    
    private func addScanningOverlay() {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Create scanning area
        let scanningArea = UIView()
        scanningArea.backgroundColor = .clear
        scanningArea.layer.borderColor = UIColor.white.cgColor
        scanningArea.layer.borderWidth = 2
        scanningArea.layer.cornerRadius = 10
        scanningArea.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scanningArea)
        
        NSLayoutConstraint.activate([
            scanningArea.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanningArea.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanningArea.widthAnchor.constraint(equalToConstant: 250),
            scanningArea.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        // Create mask to show only scanning area
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanningRect = CGRect(
            x: view.bounds.width / 2 - 125,
            y: view.bounds.height / 2 - 125,
            width: 250,
            height: 250
        )
        path.append(UIBezierPath(roundedRect: scanningRect, cornerRadius: 10).reversing())
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
    }
    
    @objc private func cancelTapped() {
        onDismiss?()
    }
}