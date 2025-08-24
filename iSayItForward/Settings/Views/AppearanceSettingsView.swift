import SwiftUI

// MARK: - Appearance settings view
struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: AppearanceSettingsViewModel
    @State private var showingPresetOptions = false
    @State private var showingLanguagePicker = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Theme preview section
                    if viewModel.showingThemePreview {
                        themePreviewSection
                    }
                    
                    // Theme selection
                    themeSection
                    
                    // Text and layout
                    textLayoutSection
                    
                    // Accessibility features
                    accessibilitySection
                    
                    // Language and region
                    languageSection
                    
                    // Display preferences
                    displayPreferencesSection
                    
                    // Quick presets
                    presetsSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(viewModel.currentColorScheme)
        .actionSheet(isPresented: $showingPresetOptions) {
            ActionSheet(
                title: Text("Appearance Presets"),
                message: Text("Choose a preset configuration"),
                buttons: [
                    .default(Text("Default Settings")) {
                        Task { await viewModel.applyDefaultSettings() }
                    },
                    .default(Text("Accessibility Optimized")) {
                        Task { await viewModel.applyAccessibilityOptimized() }
                    },
                    .default(Text("Performance Optimized")) {
                        Task { await viewModel.applyPerformanceOptimized() }
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(viewModel: viewModel)
        }
    }
    
    // MARK: - Theme preview section
    private var themePreviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Theme Preview")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyPreviewedTheme()
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .frame(width: 80)
                    
                    Button("Cancel") {
                        viewModel.dismissThemePreview()
                    }
                    .foregroundColor(.red)
                }
            }
            
            Text("Previewing \(viewModel.previewTheme?.displayName ?? "") theme")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.brandYellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandYellow, lineWidth: 2)
        )
    }
    
    // MARK: - Theme section
    private var themeSection: some View {
        SettingsCardView(title: "Theme") {
            VStack(spacing: 16) {
                Text("Choose how the app looks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    ThemeOptionRow(
                        title: theme.displayName,
                        description: themeDescription(theme),
                        isSelected: viewModel.theme == theme,
                        onSelect: {
                            Task { await viewModel.setTheme(theme) }
                        },
                        onPreview: {
                            viewModel.previewThemeTemporarily(theme)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Text and layout section
    private var textLayoutSection: some View {
        SettingsCardView(title: "Text & Layout") {
            VStack(spacing: 16) {
                // Text size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Text Size")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(viewModel.textSize.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Button("-") {
                            Task { await viewModel.decreaseTextSize() }
                        }
                        .disabled(!viewModel.canDecreaseTextSize)
                        .buttonStyle(SecondaryActionButtonStyle())
                        .frame(width: 40)
                        
                        Text("Sample text for preview")
                            .font(.body)
                            .scaleEffect(viewModel.textScaleFactor)
                            .frame(maxWidth: .infinity)
                        
                        Button("+") {
                            Task { await viewModel.increaseTextSize() }
                        }
                        .disabled(!viewModel.canIncreaseTextSize)
                        .buttonStyle(SecondaryActionButtonStyle())
                        .frame(width: 40)
                    }
                }
                
                Divider()
                
                // Layout density
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Layout Density")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(viewModel.layoutSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(LayoutDensity.allCases, id: \.self) { density in
                            Button(density.displayName) {
                                Task { await viewModel.setLayoutDensity(density) }
                            }
                            .buttonStyle(viewModel.layoutDensity == density ? PrimaryActionButtonStyle() : SecondaryActionButtonStyle())
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Accessibility section
    private var accessibilitySection: some View {
        SettingsCardView(title: "Accessibility") {
            VStack(spacing: 16) {
                HStack {
                    Text("Current Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(viewModel.accessibilityStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                ToggleRow(
                    title: "Reduce Motion",
                    description: "Minimize animations and transitions",
                    isOn: $viewModel.reducedMotion
                ) {
                    Task { await viewModel.toggleReducedMotion() }
                }
                
                ToggleRow(
                    title: "High Contrast",
                    description: "Increase contrast for better visibility",
                    isOn: $viewModel.highContrast
                ) {
                    Task { await viewModel.toggleHighContrast() }
                }
                
                // Color blindness support
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Blindness Support")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Picker("Color Blindness Support", selection: $viewModel.colorBlindnessSupport) {
                        ForEach(ColorBlindnessType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.colorBlindnessSupport) { newValue in
                        Task { await viewModel.setColorBlindnessSupport(newValue) }
                    }
                }
                
                Button("Sync with System Settings") {
                    Task { await viewModel.syncWithSystemSettings() }
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
    }
    
    // MARK: - Language section
    private var languageSection: some View {
        SettingsCardView(title: "Language & Region") {
            VStack(spacing: 16) {
                HStack {
                    Text("Language")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(viewModel.currentLanguageName) {
                        showingLanguagePicker = true
                    }
                    .foregroundColor(Color.brandYellow)
                }
                
                ToggleRow(
                    title: "24-Hour Format",
                    description: "Use 24-hour time format",
                    isOn: $viewModel.use24HourFormat
                ) {
                    Task { await viewModel.toggle24HourFormat() }
                }
            }
        }
    }
    
    // MARK: - Display preferences section
    private var displayPreferencesSection: some View {
        SettingsCardView(title: "Display Preferences") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Show Preview Images",
                    description: "Display image previews in feeds",
                    isOn: $viewModel.showPreviewImages
                ) {
                    Task { await viewModel.togglePreviewImages() }
                }
                
                ToggleRow(
                    title: "Compact Mode",
                    description: "Use compact layout to fit more content",
                    isOn: $viewModel.compactMode
                ) {
                    Task { await viewModel.toggleCompactMode() }
                }
            }
        }
    }
    
    // MARK: - Presets section
    private var presetsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Appearance Presets")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            Button("Choose Appearance Preset") {
                showingPresetOptions = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    
    // MARK: - Helper methods
    private func themeDescription(_ theme: AppTheme) -> String {
        switch theme {
        case .light:
            return "Always use light theme"
        case .dark:
            return "Always use dark theme"
        case .system:
            return "Follow system setting"
        }
    }
}

// MARK: - Theme option row
private struct ThemeOptionRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isSelected {
                Button("Preview") {
                    onPreview()
                }
                .font(.caption)
                .foregroundColor(Color.brandYellow)
            }
            
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.brandYellow : .gray)
            }
        }
        .padding()
        .background(isSelected ? Color.brandYellow.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.brandYellow : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Language picker view
private struct LanguagePickerView: View {
    @ObservedObject var viewModel: AppearanceSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.availableLanguageOptions, id: \.0) { languageCode, languageName in
                    HStack {
                        Text(languageName)
                        
                        Spacer()
                        
                        if viewModel.preferredLanguage == languageCode {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.brandYellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.setLanguage(languageCode)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsView(viewModel: AppearanceSettingsViewModel())
        }
    }
}