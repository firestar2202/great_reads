import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var bookManager = BookManager()
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        TabView {
            BooksView(bookManager: bookManager, userManager: userManager, authManager: authManager)
                .tabItem {
                    Label("Books", systemImage: "book.fill")
                }
            
            FriendsListView(userManager: userManager)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            FeedView(userManager: userManager)
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
            
            VibeView(userManager: userManager)
                .tabItem {
                    Label("My Vibe", systemImage: "sparkles")
                }
        }
        .onAppear {
            setupUserData()
        }
    }
    
    private func setupUserData() {
        guard let userId = authManager.currentUserId else { return }
        
        bookManager.fetchUserBooks(userId: userId)
        
        Task {
            try? await userManager.fetchUserProfile(userId: userId)
            try? await bookManager.addExampleBooksIfNeeded(userId: userId)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
