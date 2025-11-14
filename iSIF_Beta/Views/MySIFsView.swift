import SwiftUI

struct MySIFsView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    @State private var sifs: [SIF] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let sifService = SIFDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                BrandTheme.backgroundGradient.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading your SIFs...")
                } else if sifs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray.full")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("My SIFs")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Text("You don't have any SIFs yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding()
                } else {
                    List {
                        ForEach(sifs) { sif in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sif.subject ?? "No Subject")
                                    .font(.headline)
                                Text("To: \(sif.recipients.map { $0.name }.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text(sif.createdAt, style: .date)
                                        .font(.caption)
                                    Spacer()
                                    Text(sif.status)
                                        .font(.caption)
                                        .foregroundColor(sif.status == "sent" ? .green : .orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My SIFs")
            .task {
                await loadSIFs()
            }
            .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func loadSIFs() async {
        guard let userUID = authState.uid else {
            errorMessage = "You must be logged in to view SIFs"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            sifs = try await sifService.fetchUserSIFs(for: userUID)
        } catch {
            print("❌ Failed to fetch SIFs:", error)
            errorMessage = "Failed to load SIFs: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let authState = AuthState()
    authState.uid = "preview-user"
    let tabRouter = TabRouter()
    
    return MySIFsView()
        .environmentObject(tabRouter)
        .environmentObject(authState)
}
