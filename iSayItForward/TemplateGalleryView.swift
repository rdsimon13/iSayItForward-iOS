import SwiftUI

struct TemplateGalleryView: View {
    // Example of a grid layout for templates
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<10) { index in
                            VStack {
                                Text("Template \(index + 1)")
                                    .fontWeight(.bold)
                                Text("A short description of the template's purpose.")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(height: 150)
                            .frostedGlass()
                        }
                    }
                    .padding()
                }
                .navigationTitle("Template Gallery")
            }
        }
    }
}
