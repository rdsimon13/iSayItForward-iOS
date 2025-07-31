import SwiftUI

// Modern text field style with improved design
struct PillTextFieldStyle: TextFieldStyle {
    let iconName: String?
    
    init(iconName: String? = nil) {
        self.iconName = iconName
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 12) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .foregroundColor(.neutralGray400)
                    .frame(width: 20)
            }
            
            configuration
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.neutralGray200, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
