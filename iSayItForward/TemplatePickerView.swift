import SwiftUI

struct TemplatePickerView: View {
    @Binding var selectedTemplate: TemplateItem?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedCategory: TemplateCategory = .encouragement
    @State private var searchText = ""
    
    // Sample templates - in a real app, these would come from a data source
    private let sampleTemplates: [TemplateItem] = [
        TemplateItem(name: "Encouragement Note", message: "You're doing great! Keep up the amazing work.", imageName: "heart.fill", category: .encouragement),
        TemplateItem(name: "Holiday Greeting", message: "Wishing you and your family a wonderful holiday season!", imageName: "gift.fill", category: .holiday),
        TemplateItem(name: "Announcement", message: "We're excited to share some great news with you!", imageName: "megaphone.fill", category: .announcement),
        TemplateItem(name: "Sympathy Message", message: "Our thoughts and prayers are with you during this difficult time.", imageName: "heart.text.square", category: .sympathy),
        TemplateItem(name: "School Update", message: "Here's an important update from your school.", imageName: "graduationcap.fill", category: .school),
        TemplateItem(name: "Spiritual Reflection", message: "May you find peace and strength in your faith today.", imageName: "cross.fill", category: .spiritual),
        TemplateItem(name: "Patriotic Message", message: "Proud to be American! Thank you to all who serve.", imageName: "flag.fill", category: .patriotic),
        TemplateItem(name: "Seasonal Greeting", message: "Hope you're enjoying this beautiful season!", imageName: "leaf.fill", category: .seasonal),
        TemplateItem(name: "Blank Template", message: "", imageName: "doc.plaintext", category: .blank)
    ]
    
    private var filteredTemplates: [TemplateItem] {
        let categoryFiltered = sampleTemplates.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.message.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ? 
                                Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedCategory == category ? 
                                .white : .primary
                            )
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Templates grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id
                            ) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedTemplate == nil)
            )
        }
    }
}

struct TemplateCard: View {
    let template: TemplateItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.imageName)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            Text(template.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if !template.message.isEmpty {
                Text(template.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Blank template")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
            
            HStack {
                Text(template.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.blue : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

// Preview
struct TemplatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplatePickerView(selectedTemplate: .constant(nil))
    }
}