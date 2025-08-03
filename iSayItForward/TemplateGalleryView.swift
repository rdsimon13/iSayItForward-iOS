import SwiftUI

struct TemplateGalleryView: View {
    // We'll use the demo templates defined in your TemplateLibrary file.
    let templates: [TemplateItem] = TemplateLibrary.templates

    // Helper to group templates by their category for display.
    var categorizedTemplates: [TemplateCategory: [TemplateItem]] {
        Dictionary(grouping: templates, by: { $0.category })
    }

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Iterate through all possible categories to maintain order
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        // Check if there are any templates for this category
                        if let items = categorizedTemplates[category], !items.isEmpty {
                            
                            // Category Header Text
                            Text(category.rawValue)
                                .font(.title2.weight(.bold))
                                .foregroundColor(Color.brandDarkBlue)
                                .padding(.horizontal)

                            // Cards for each template in the category
                            VStack(spacing: 16) {
                                ForEach(items) { template in
                                    TemplateCardView(template: template)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Template Gallery")
    }
}

// A new custom card view for displaying a single template item.
private struct TemplateCardView: View {
    let template: TemplateItem

    var body: some View {
        Button(action: {
            // Action to perform when a template is selected will go here
            print("\(template.name) selected!")
        }) {
            HStack(spacing: 16) {
                // This will now render the actual image for each template.
                // Make sure you have images in your Assets catalog with matching names
                // (e.g., "QuestionMarks.png", "BabyShower.png").
                Image(template.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Text(template.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .foregroundColor(Color.brandDarkBlue)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TemplateGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TemplateGalleryView()
        }
    }
}
