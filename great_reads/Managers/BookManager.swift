import Foundation
import FirebaseFirestore
import Combine

@MainActor
class BookManager: ObservableObject {
    @Published var books: [FirestoreBook] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Fetch books for current user (with real-time updates)
    func fetchUserBooks(userId: String) {
        print("📚 Setting up listener for user: \(userId)")
         
        // Remove old listener if exists
        listener?.remove()
        
        // Set up real-time listener
        listener = db.collection("books")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error fetching books: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found")
                    return
                }
                
                print("🔄 Listener fired! Found \(documents.count) books")
                
                Task { @MainActor in
                    self?.books = documents.compactMap { doc -> FirestoreBook? in
                        try? doc.data(as: FirestoreBook.self)
                    }
                    print("✅ Updated books array: \(self?.books.count ?? 0) books")
                }
            }
    }
    
    // Add a new book
    func addBook(
        title: String,
        author: String,
        tags: [String],
        userId: String,
        bookDescription: String? = nil,
        coverImageURL: String? = nil,
        isbn: String? = nil,
        pageCount: Int? = nil,
        publishedDate: String? = nil,
        publisher: String? = nil,
        googleBooksId: String? = nil,
        dateRead: Date? = nil,
        review: String? = nil
    ) async throws {
        let book = FirestoreBook(
            title: title,
            author: author,
            tags: tags,
            userId: userId,
            createdAt: Date(),
            bookDescription: bookDescription,
            coverImageURL: coverImageURL,
            isbn: isbn,
            pageCount: pageCount,
            publishedDate: publishedDate,
            publisher: publisher,
            googleBooksId: googleBooksId,
            dateRead: dateRead,
            review: review
        )
        
        try db.collection("books").addDocument(from: book)
    }
    
    // Delete a book
    func deleteBook(_ book: FirestoreBook) async throws {
        guard let id = book.id else { return }
        try await db.collection("books").document(id).delete()
    }
    
    // Add example books for a user (only if they have no books)
    func addExampleBooksIfNeeded(userId: String) async throws {
        // Check if user already has books in Firestore
        let snapshot = try await db.collection("books")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        // Only add examples if user has no books
        guard snapshot.documents.isEmpty else { return }
        
        let exampleBooks: [(String, String, [String])] = [
            ("The Midnight Library", "Matt Haig", ["literature", "fantasy"]),
            ("Project Hail Mary", "Andy Weir", ["scifi", "thriller"]),
            ("Tomorrow, and Tomorrow, and Tomorrow", "Gabrielle Zevin", ["literature", "romance"]),
            ("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid", ["romance", "literature"]),
            ("Anxious People", "Fredrik Backman", ["literature"]),
            ("The Silent Patient", "Alex Michaelides", ["thriller", "mystery"]),
            ("Educated", "Tara Westover", ["nonfiction", "history"]),
            ("Where the Crawdads Sing", "Delia Owens", ["mystery", "romance"]),
            ("The House in the Cerulean Sea", "TJ Klune", ["fantasy", "romance"]),
            ("Mexican Gothic", "Silvia Moreno-Garcia", ["horror", "mystery"])
        ]
        
        for (title, author, tags) in exampleBooks {
            try await addBook(title: title, author: author, tags: tags, userId: userId)
        }
    }
    
    // Stop listening when done
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
