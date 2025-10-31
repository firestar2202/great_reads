import Foundation
import FirebaseFirestore
import Combine

// Activity item model
struct ActivityItem: Identifiable {
    let id: String
    let book: FirestoreBook
    let user: FirestoreUser?
    let timestamp: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

@MainActor
final class FeedManager: ObservableObject {
    @Published var activityItems: [ActivityItem] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    // Fetch recent books from friends
    func fetchFriendActivity(friendIds: [String]) async {
        guard !friendIds.isEmpty else {
            activityItems = []
            return
        }
        
        isLoading = true
        
        do {
            // Fetch books from all friends
            // Note: Firestore 'in' queries are limited to 10 items at a time
            let batchSize = 10
            var allBooks: [FirestoreBook] = []
            
            for i in stride(from: 0, to: friendIds.count, by: batchSize) {
                let batch = Array(friendIds[i..<min(i + batchSize, friendIds.count)])
                
                let snapshot = try await db.collection("books")
                    .whereField("userId", in: batch)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 50)
                    .getDocuments()
                
                let books = snapshot.documents.compactMap { doc -> FirestoreBook? in
                    try? doc.data(as: FirestoreBook.self)
                }
                
                allBooks.append(contentsOf: books)
            }
            
            // Sort all books by timestamp
            allBooks.sort { $0.createdAt > $1.createdAt }
            
            // Take top 50 most recent
            allBooks = Array(allBooks.prefix(50))
            
            // Fetch user info for each book
            var items: [ActivityItem] = []
            for book in allBooks {
                let user = try? await getUserInfo(userId: book.userId)
                let item = ActivityItem(
                    id: book.id ?? UUID().uuidString,
                    book: book,
                    user: user,
                    timestamp: book.createdAt
                )
                items.append(item)
            }
            
            self.activityItems = items
        } catch {
            print("Error fetching friend activity: \(error)")
        }
        
        isLoading = false
    }
    
    // Get user info from cache or fetch from Firestore
    private var userCache: [String: FirestoreUser] = [:]
    
    private func getUserInfo(userId: String) async throws -> FirestoreUser? {
        // Check cache first
        if let cached = userCache[userId] {
            return cached
        }
        
        // Fetch from Firestore
        let document = try await db.collection("users").document(userId).getDocument()
        let user = try? document.data(as: FirestoreUser.self)
        
        // Cache it
        if let user = user {
            userCache[userId] = user
        }
        
        return user
    }
}
