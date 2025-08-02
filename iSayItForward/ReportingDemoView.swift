import SwiftUI

struct ReportingDemoView: View {
    @State private var showingReportOverlay = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Reporting System Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandDarkBlue)
                
                VStack(spacing: 16) {
                    // Sample content card that can be reported
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            VStack(alignment: .leading) {
                                Text("Sample User")
                                    .font(.headline)
                                    .foregroundColor(Color.brandDarkBlue)
                                Text("2 hours ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Report") {
                                showingReportOverlay = true
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        Text("This is a sample message content that demonstrates the reporting functionality. Users can report inappropriate content using the report button.")
                            .font(.body)
                            .foregroundColor(Color.brandDarkBlue)
                    }
                    .padding()
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    
                    // Notification status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notification Status")
                            .font(.headline)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        HStack {
                            Image(systemName: notificationManager.isNotificationPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(notificationManager.isNotificationPermissionGranted ? .green : .red)
                            
                            Text(notificationManager.isNotificationPermissionGranted ? "Notifications Enabled" : "Notifications Disabled")
                                .foregroundColor(Color.brandDarkBlue)
                        }
                        
                        if !notificationManager.isNotificationPermissionGranted {
                            Button("Enable Notifications") {
                                Task {
                                    await notificationManager.requestNotificationPermission()
                                }
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reporting Demo")
            
            // Report overlay
            if showingReportOverlay {
                ReportOverlayView(isPresented: $showingReportOverlay)
            }
        }
        .onAppear {
            notificationManager.checkNotificationPermission()
        }
    }
}

struct ReportingDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReportingDemoView()
        }
    }
}