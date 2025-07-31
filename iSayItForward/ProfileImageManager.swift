import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

@MainActor
class ProfileImageManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadProgress: Double = 0.0
    
    private let storage = Storage.storage()
    private let imageCache = NSCache<NSString, UIImage>()
    
    init() {
        // Configure cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Image Selection
    
    func selectImageFromLibrary() {
        // This will be called from a PhotosPicker in the view
    }
    
    func selectImageFromCamera() {
        // This will be called from an ImagePicker in the view
    }
    
    // MARK: - Image Upload
    
    func uploadProfileImage(_ image: UIImage) async -> String? {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        uploadProgress = 0.0
        
        do {
            // Compress image
            guard let imageData = compressImage(image) else {
                errorMessage = "Failed to compress image"
                isLoading = false
                return nil
            }
            
            // Create storage reference
            let storageRef = storage.reference()
            let profileImageRef = storageRef.child("profile_images/\(uid).jpg")
            
            // Upload with progress tracking
            let uploadTask = profileImageRef.putData(imageData, metadata: nil)
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self else { return }
                let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                Task { @MainActor in
                    self.uploadProgress = progress
                }
            }
            
            // Wait for upload completion
            _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await profileImageRef.downloadURL()
            
            // Cache the image
            cacheImage(image, for: downloadURL.absoluteString)
            profileImage = image
            
            isLoading = false
            uploadProgress = 1.0
            
            return downloadURL.absoluteString
            
        } catch {
            errorMessage = "Failed to upload image: \(error.localizedDescription)"
            isLoading = false
            uploadProgress = 0.0
            return nil
        }
    }
    
    // MARK: - Image Loading
    
    func loadProfileImage(from urlString: String?) async {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            profileImage = nil
            return
        }
        
        // Check cache first
        if let cachedImage = getCachedImage(for: urlString) {
            profileImage = cachedImage
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                profileImage = image
                cacheImage(image, for: urlString)
            }
        } catch {
            errorMessage = "Failed to load profile image: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Image Processing
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize image if needed
        let maxSize: CGFloat = 1024
        let resizedImage = resizeImage(image, to: maxSize)
        
        // Compress to JPEG with 0.8 quality
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    private func resizeImage(_ image: UIImage, to maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Caching
    
    private func cacheImage(_ image: UIImage, for key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    private func getCachedImage(for key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Image Deletion
    
    func deleteProfileImage() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let storageRef = storage.reference()
            let profileImageRef = storageRef.child("profile_images/\(uid).jpg")
            
            try await profileImageRef.delete()
            
            profileImage = nil
            selectedImage = nil
            isLoading = false
            
            return true
        } catch {
            errorMessage = "Failed to delete image: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Retry Mechanism
    
    func retryImageUpload() async -> String? {
        guard let image = selectedImage else { return nil }
        return await uploadProfileImage(image)
    }
    
    func retryImageLoad(from urlString: String?) async {
        await loadProfileImage(from: urlString)
    }
}

// MARK: - Supporting Types

struct ImagePickerError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}