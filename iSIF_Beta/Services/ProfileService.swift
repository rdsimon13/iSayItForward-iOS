import Foundation
import UIKit

class ProfileService {
    
    // Function to upload profile photo
    func uploadProfilePhoto(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert image to Data
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "ProfileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"])))
            return
        }
        
        // Assuming there's a URL endpoint for the photo upload
        let url = URL(string: "https://yourapi.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = imageData
        request.setValue("application/jpeg", forHTTPHeaderField: "Content-Type")
        
        // URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            // Handle response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let errorMsg = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "ProfileService", code: -2, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                return
            }
            // Assuming the response returns the uploaded photo URL
            let photoURL = "https://yourapi.com/uploads/profile_photo.jpg" // replace with actual URL from response
            completion(.success(photoURL))
        }
        
        task.resume()
    }
    
    // Function to persist the uploaded profile photo URL
    func saveProfilePhotoURL(url: String) {
        UserDefaults.standard.set(url, forKey: "profilePhotoURL")
    }
    
    // Function to retrieve the stored profile photo URL
    func getProfilePhotoURL() -> String? {
        return UserDefaults.standard.string(forKey: "profilePhotoURL")
    }
}