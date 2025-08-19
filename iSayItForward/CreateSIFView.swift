import SwiftUI

struct CreateSIFView: View {
    @State private var recipient: String = ""
    @State private var message: String = "Your message here..."
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Create a SIF")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // --- Main Composition Card ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recipient")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("Email or Phone Number", text: $recipient)
                                .padding(12)
                                .background(.white.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Message")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextEditor(text: $message)
                                .frame(height: 200)
                                .cornerRadius(8)
                                .padding(4) // Padding inside to avoid text touching the edges
                                
                        }
                        .foregroundColor(.white)
                        .frostedGlass()
                        
                        // --- Action Buttons ---
                        HStack {
                            Button("Schedule") {
                                // Add scheduling action
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button("Send Now") {
                                // Add send action
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding()
                }
                .navigationTitle("Compose")
                .navigationBarHidden(true)
            }
        }
    }
}
