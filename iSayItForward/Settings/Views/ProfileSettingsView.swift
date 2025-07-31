import SwiftUI

// MARK: - Profile settings view
struct ProfileSettingsView: View {
    @ObservedObject var viewModel: ProfileSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Profile image section
                    profileImageSection
                    
                    // Basic information
                    basicInfoSection
                    
                    // Contact information
                    contactInfoSection
                    
                    // Skills and expertise
                    skillsSection
                    
                    // Bio section
                    bioSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.isEditing {
                    HStack {
                        Button("Cancel") {
                            viewModel.discardChanges()
                        }
                        .foregroundColor(.red)
                        
                        Button("Save") {
                            Task {
                                await viewModel.saveChanges()
                            }
                        }
                        .disabled(!viewModel.canSave)
                        .foregroundColor(viewModel.canSave ? Color.brandYellow : .gray)
                    }
                } else {
                    Button("Edit") {
                        viewModel.isEditing = true
                    }
                    .foregroundColor(Color.brandDarkBlue)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerView { image in
                // Handle selected image
                viewModel.profileImageURL = "placeholder_url"
            }
        }
    }
    
    // MARK: - Profile image section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.showingImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.brandDarkBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    if let imageURL = viewModel.profileImageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color.brandDarkBlue)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color.brandDarkBlue)
                    }
                    
                    if viewModel.isEditing {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.brandYellow)
                                    .clipShape(Circle())
                                    .offset(x: -10, y: -10)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
            }
            .disabled(!viewModel.isEditing)
            
            if viewModel.isEditing {
                Text("Tap to change profile photo")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    // MARK: - Basic information section
    private var basicInfoSection: some View {
        SettingsCardView(title: "Basic Information") {
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Display Name",
                    text: $viewModel.displayName,
                    placeholder: "Enter your display name",
                    isEditing: viewModel.isEditing,
                    characterCount: viewModel.characterCountForDisplayName
                )
                
                CustomTextField(
                    title: "Location",
                    text: $viewModel.location,
                    placeholder: "City, State/Country",
                    isEditing: viewModel.isEditing
                )
            }
        }
    }
    
    // MARK: - Contact information section
    private var contactInfoSection: some View {
        SettingsCardView(title: "Contact Information") {
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Phone Number",
                    text: $viewModel.phoneNumber,
                    placeholder: "+1 (555) 123-4567",
                    isEditing: viewModel.isEditing,
                    keyboardType: .phonePad
                )
                
                CustomTextField(
                    title: "Website",
                    text: $viewModel.website,
                    placeholder: "https://yourwebsite.com",
                    isEditing: viewModel.isEditing,
                    keyboardType: .URL
                )
            }
        }
    }
    
    // MARK: - Skills section
    private var skillsSection: some View {
        SettingsCardView(title: "Skills & Expertise") {
            VStack(spacing: 16) {
                // Skills
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Skills")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(viewModel.skillsCount)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.isEditing {
                        HStack {
                            TextField("Add a skill", text: $viewModel.newSkill)
                                .textFieldStyle(PillTextFieldStyle())
                            
                            Button("Add") {
                                viewModel.addSkill()
                            }
                            .disabled(!viewModel.canAddSkill)
                            .buttonStyle(SecondaryActionButtonStyle())
                            .frame(width: 60)
                        }
                    }
                    
                    FlexibleTagView(
                        tags: viewModel.skills,
                        canRemove: viewModel.isEditing
                    ) { skill in
                        viewModel.removeSkill(skill)
                    }
                }
                
                Divider()
                
                // Expertise
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Areas of Expertise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(viewModel.expertiseCount)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.isEditing {
                        HStack {
                            TextField("Add expertise area", text: $viewModel.newExpertise)
                                .textFieldStyle(PillTextFieldStyle())
                            
                            Button("Add") {
                                viewModel.addExpertise()
                            }
                            .disabled(!viewModel.canAddExpertise)
                            .buttonStyle(SecondaryActionButtonStyle())
                            .frame(width: 60)
                        }
                    }
                    
                    FlexibleTagView(
                        tags: viewModel.expertise,
                        canRemove: viewModel.isEditing
                    ) { expertise in
                        viewModel.removeExpertise(expertise)
                    }
                }
            }
        }
    }
    
    // MARK: - Bio section
    private var bioSection: some View {
        SettingsCardView(title: "About You") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(viewModel.characterCountForBio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isEditing {
                    TextEditor(text: $viewModel.bio)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text(viewModel.bio.isEmpty ? "No bio added yet" : viewModel.bio)
                        .font(.body)
                        .foregroundColor(viewModel.bio.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Settings card view
private struct SettingsCardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.brandDarkBlue)
            
            content
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Custom text field
private struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isEditing: Bool
    let characterCount: String?
    let keyboardType: UIKeyboardType
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isEditing: Bool,
        characterCount: String? = nil,
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.characterCount = characterCount
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let characterCount = characterCount {
                    Text(characterCount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isEditing {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PillTextFieldStyle())
                    .keyboardType(keyboardType)
            } else {
                Text(text.isEmpty ? "Not provided" : text)
                    .font(.body)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Flexible tag view
private struct FlexibleTagView: View {
    let tags: [String]
    let canRemove: Bool
    let onRemove: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagView(
                    text: tag,
                    canRemove: canRemove,
                    onRemove: { onRemove(tag) }
                )
            }
        }
    }
}

// MARK: - Tag view
private struct TagView: View {
    let text: String
    let canRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.brandYellow.opacity(0.2))
        .foregroundColor(Color.brandDarkBlue)
        .clipShape(Capsule())
    }
}

// MARK: - Image picker placeholder
private struct ImagePickerView: View {
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack {
            Text("Image Picker")
                .font(.title)
            Text("Camera/Photo Library integration would go here")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Preview
struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileSettingsView(viewModel: ProfileSettingsViewModel())
        }
    }
}