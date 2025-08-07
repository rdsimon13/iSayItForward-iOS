
import SwiftUI

struct DocumentUploadView: View {
    @Binding var attachments: [Attachment]

    var body: some View {
        AttachmentPickerView(attachments: $attachments)
    }
}
