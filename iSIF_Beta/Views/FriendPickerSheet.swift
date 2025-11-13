//
//  FriendPickerSheet.swift
//  iSIF_Beta
//
//  Minimal SwiftUI wrapper so ComposeSIFView can present a friend picker
//  without using a `coder:` initializer. Replace implementation later.

import SwiftUI

struct FriendPickerSheet: View {
    let deliveryType: DeliveryType
    @Binding var selected: [SIFRecipient]

    var body: some View {
        // Temporary stub UI to keep the app compiling.
        VStack(spacing: 16) {
            Text("Select Recipients")
                .font(.headline)
            Text("Temporary picker to unblock build.")
                .foregroundColor(.secondary)
            Button("Done") { } // parent dismisses the sheet
        }
        .padding()
    }
}
