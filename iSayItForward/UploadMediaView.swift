
import SwiftUI

struct UploadMediaView: View {
    @Binding var attachments: [Attachment]

    var body: some View {
        AttachmentPickerView(attachments: $attachments)
    }
}
