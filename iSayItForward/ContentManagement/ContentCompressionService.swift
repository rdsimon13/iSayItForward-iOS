import Foundation
import UIKit
import AVFoundation

/// Service for compressing different types of content
actor ContentCompressionService {
    static let shared = ContentCompressionService()
    
    private let tempDirectory: URL
    
    private init() {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ContentCompression")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    /// Compresses a file based on its media type
    func compressFile(at url: URL, mediaType: MediaType) async throws -> URL {
        switch mediaType {
        case .photo:
            return try await compressImage(at: url)
        case .video:
            return try await compressVideo(at: url)
        case .audio:
            return try await compressAudio(at: url)
        case .document, .text:
            // Documents and text files are typically already compressed or small
            return url
        }
    }
    
    /// Compresses an image file
    private func compressImage(at url: URL) async throws -> URL {
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw ContentError.compressionFailed
        }
        
        // Calculate target size (max 1920x1920 for photos)
        let maxDimension: CGFloat = 1920
        let targetSize = calculateImageSize(for: image.size, maxDimension: maxDimension)
        
        // Resize image
        let resizedImage = image.resized(to: targetSize)
        
        // Compress to JPEG with quality 0.8
        guard let compressedData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw ContentError.compressionFailed
        }
        
        // Save compressed image
        let compressedURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        try compressedData.write(to: compressedURL)
        
        return compressedURL
    }
    
    /// Compresses a video file
    private func compressVideo(at url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw ContentError.compressionFailed
        }
        
        let compressedURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .mp4
        
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: compressedURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: ContentError.compressionFailed)
                default:
                    continuation.resume(throwing: ContentError.compressionFailed)
                }
            }
        }
    }
    
    /// Compresses an audio file
    private func compressAudio(at url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ContentError.compressionFailed
        }
        
        let compressedURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .m4a
        
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: compressedURL)
                case .failed, .cancelled:
                    continuation.resume(throwing: ContentError.compressionFailed)
                default:
                    continuation.resume(throwing: ContentError.compressionFailed)
                }
            }
        }
    }
    
    /// Cleans up temporary compressed files
    func cleanupTempFiles() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to cleanup temp files: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateImageSize(for originalSize: CGSize, maxDimension: CGFloat) -> CGSize {
        let aspectRatio = originalSize.width / originalSize.height
        
        if originalSize.width > originalSize.height {
            // Landscape or square
            if originalSize.width > maxDimension {
                return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            }
        } else {
            // Portrait
            if originalSize.height > maxDimension {
                return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        return originalSize
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}