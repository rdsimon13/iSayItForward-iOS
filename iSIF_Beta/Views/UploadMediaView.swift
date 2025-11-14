
import SwiftUI
import PhotosUI

struct UploadMediaView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var uploadProgress: [String: Double] = [:]
    @State private var uploadError: String?
    @State private var showingErrorAlert = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .foregroundColor(.teal.opacity(0.7))
                
                VStack(alignment: .leading) {
                    Text("Upload Media")
                        .font(.headline)
                    Text("Images & Videos (30MB max)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Button(action: { showingCamera = true }) {
                        Image(systemName: "camera")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                        Image(systemName: "photo.stack")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Selected media preview
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: {
                                selectedImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .onChange(of: selectedItems) { newItems in
            guard !newItems.isEmpty else { return }
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            // Check image size (convert to JPEG for size check)
                            if let jpegData = image.jpegData(compressionQuality: 0.7) {
                                if jpegData.count > 30 * 1024 * 1024 {
                                    await MainActor.run {
                                        uploadError = "Image is too large (max 30MB)"
                                        showingErrorAlert = true
                                    }
                                    continue
                                }
                            }
                            await MainActor.run {
                                if !selectedImages.contains(image) {
                                    selectedImages.append(image)
                                }
                            }
                        }
                    }
                }
                await MainActor.run {
                    selectedItems.removeAll()
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image = image {
                    selectedImages.append(image)
                }
            }
        }
        .alert("Upload Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(uploadError ?? "Unknown error")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}
