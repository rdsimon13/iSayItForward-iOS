
import SwiftUI
import PhotosUI

struct UploadMediaView: View {
    @Binding var selectedImage: UIImage?
    @Binding var contentAttachments: [ContentAttachment]
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            if selectedImage != nil || !contentAttachments.filter({ $0.contentType == .photo }).isEmpty {
                // Show selected content
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(8)
                    }
                    
                    ForEach(contentAttachments.filter { $0.contentType == .photo }) { attachment in
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            Text(attachment.fileName)
                                .font(.caption)
                            Spacer()
                            Text(ByteFormatter.format(bytes: attachment.fileSize))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                // Upload interface
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .foregroundColor(.teal.opacity(0.4))

                        Text("Select Photos")
                            .foregroundColor(.teal)
                            .font(.headline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .onChange(of: selectedItems) { items in
            processSelectedItems(items)
        }
    }
    
    private func processSelectedItems(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            selectedImage = image
                            let attachment = ContentAttachment(
                                contentType: .photo,
                                fileName: "photo_\(Date().timeIntervalSince1970).jpg",
                                fileSize: data.count,
                                metadata: [
                                    "width": "\(Int(image.size.width))",
                                    "height": "\(Int(image.size.height))"
                                ]
                            )
                            contentAttachments.append(attachment)
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
        selectedItems.removeAll()
    }
}
