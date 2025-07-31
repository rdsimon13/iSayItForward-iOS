import SwiftUI

// MARK: - Search Integration Test View
struct SearchIntegrationTestView: View {
    @State private var showingSearch = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Search System Integration Test")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button("Test Search View") {
                    showingSearch = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
                
                Button("Test Search Service") {
                    testSearchService()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                Button("Test Search Analytics") {
                    testSearchAnalytics()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
    }
    
    private func testSearchService() {
        let searchService = SearchService()
        let filter = SearchFilter()
        
        searchService.search(query: "birthday", filters: filter) { results in
            print("Search completed with \(results.count) results")
            for result in results.prefix(3) {
                print("- \(result.title) (\(result.type.rawValue))")
            }
        }
    }
    
    private func testSearchAnalytics() {
        let analytics = SearchAnalytics()
        let filter = SearchFilter()
        
        analytics.trackSearchStarted(query: "test", filters: filter)
        analytics.trackSearchCompleted(query: "test", resultCount: 5, filters: filter)
        
        print("Analytics test completed")
    }
}

// MARK: - Preview
struct SearchIntegrationTestView_Previews: PreviewProvider {
    static var previews: some View {
        SearchIntegrationTestView()
    }
}