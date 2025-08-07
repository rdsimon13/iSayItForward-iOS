import SwiftUI

struct SendSIFView: View {
    // MARK: - Properties
    @Binding var sif: SIFItem
    @State private var showingSendOptions = false
    @StateObject private var sendService = SendSIFService.shared
    
    // Backward compatibility for existing usage
    let onSend: (() -> Void)?
    
    // MARK: - Initializers
    init(sif: Binding<SIFItem>) {
        self._sif = sif
        self.onSend = nil
    }
    
    // Backward compatibility initializer
    init(onSend: @escaping () -> Void) {
        self._sif = .constant(SIFItem(
            authorUid: "",
            recipients: [],
            subject: "",
            message: "",
            createdDate: Date(),
            scheduledDate: Date()
        ))
        self.onSend = onSend
    }

    var body: some View {
        Button(action: {
            if let onSend = onSend {
                // Backward compatibility
                onSend()
            } else {
                // New functionality
                showingSendOptions = true
            }
        }) {
            HStack {
                Image(systemName: sif.isInProgress ? "arrow.up.circle.fill" : "paperplane.fill")
                    .foregroundColor(.white)
                
                Text(buttonText)
                    .font(.headline.weight(.semibold))
                
                if sif.isInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(sif.isInProgress && onSend == nil)
        .sheet(isPresented: $showingSendOptions) {
            SendOptionsView(sif: $sif)
        }
    }
    
    private var buttonText: String {
        if let _ = onSend {
            return "Send SIF"
        }
        
        switch sif.sendingStatus {
        case .draft:
            return "Send SIF"
        case .scheduled:
            return "Scheduled"
        case .uploading:
            return "Uploading..."
        case .sending:
            return "Sending..."
        case .sent:
            return "Sent"
        case .failed:
            return "Retry Send"
        case .cancelled:
            return "Send SIF"
        }
    }
}
