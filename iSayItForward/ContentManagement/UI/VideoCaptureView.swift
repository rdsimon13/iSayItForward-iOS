import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

/// View for capturing videos using the camera
struct VideoCaptureView: View {
    let onVideoCaptured: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VideoCaptureRepresentable(onVideoCaptured: { url in
            onVideoCaptured(url)
            dismiss()
        }, onCancel: {
            dismiss()
        })
        .ignoresSafeArea()
    }
}

/// UIViewControllerRepresentable wrapper for UIImagePickerController for video
struct VideoCaptureRepresentable: UIViewControllerRepresentable {
    let onVideoCaptured: (URL) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        
        if #available(iOS 14.0, *) {
            picker.mediaTypes = [UTType.movie.identifier]
        } else {
            picker.mediaTypes = [kUTTypeMovie as String]
        }
        
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = 300 // 5 minutes max
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCaptureRepresentable
        
        init(_ parent: VideoCaptureRepresentable) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoCaptured(videoURL)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}