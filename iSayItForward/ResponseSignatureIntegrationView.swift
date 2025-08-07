import SwiftUI

/// Integration view for testing the complete response and signature system
struct ResponseSignatureIntegrationView: View {
    @State private var selectedTab = 0
    @State private var showingSignaturePad = false
    @State private var testSignature: UIImage?
    
    // Test data
    private let testSIF = SIFItem(
        authorUid: "test-user",
        recipients: ["test@example.com"],
        subject: "Test SIF for Integration",
        message: "This is a test SIF message to demonstrate the response and signature integration functionality.",
        createdDate: Date(),
        scheduledDate: Date().addingTimeInterval(3600)
    )
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Response Composer Tab
            NavigationView {
                ResponseComposerView(
                    sifItem: testSIF,
                    onResponseSubmitted: {
                        print("Response submitted successfully!")
                        selectedTab = 1 // Switch to responses list
                    },
                    onCancel: {
                        print("Response composition cancelled")
                    }
                )
            }
            .tabItem {
                Image(systemName: "plus.bubble")
                Text("Compose")
            }
            .tag(0)
            
            // Responses List Tab
            ResponseListView(sifId: testSIF.id)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Responses")
                }
                .tag(1)
            
            // Impact Analytics Tab
            ImpactMetricsView()
                .tabItem {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Analytics")
                }
                .tag(2)
            
            // Signature Test Tab
            NavigationView {
                VStack(spacing: 20) {
                    Text("Signature Testing")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    if let signature = testSignature {
                        VStack(spacing: 15) {
                            Text("Current Signature:")
                                .font(.headline)
                            
                            Image(uiImage: signature)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding()
                            
                            Button("Clear Signature") {
                                testSignature = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Text("No signature captured yet")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Button("Create New Signature") {
                        showingSignaturePad = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
            }
            .tabItem {
                Image(systemName: "signature")
                Text("Signature")
            }
            .tag(3)
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignaturePadView(
                onSignatureComplete: { image in
                    testSignature = image
                    showingSignaturePad = false
                },
                onCancel: {
                    showingSignaturePad = false
                }
            )
        }
    }
}

// MARK: - Preview
struct ResponseSignatureIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        ResponseSignatureIntegrationView()
    }
}