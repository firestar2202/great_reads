import Foundation
import Combine

// MARK: - Google Books Models
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
    let totalItems: Int
}

struct GoogleBookItem: Codable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo
    
    struct VolumeInfo: Codable {
        let title: String
        let authors: [String]?
        let publisher: String?
        let publishedDate: String?
        let description: String?
        let pageCount: Int?
        let categories: [String]?
        let imageLinks: ImageLinks?
        let averageRating: Double?
        let ratingsCount: Int?
        let industryIdentifiers: [IndustryIdentifier]?
        
        struct ImageLinks: Codable {
            let smallThumbnail: String?
            let thumbnail: String?
        }
        
        struct IndustryIdentifier: Codable {
            let type: String
            let identifier: String
        }
    }
    
    // Helper computed properties
    var displayTitle: String {
        volumeInfo.title
    }
    
    var displayAuthors: String {
        volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author"
    }
    
    var displayDescription: String {
        volumeInfo.description ?? "No description available"
    }
    
    var coverImageURL: String? {
        // Prefer larger thumbnail, fall back to small
        guard let urlString = volumeInfo.imageLinks?.thumbnail ?? volumeInfo.imageLinks?.smallThumbnail else {
            return nil
        }
        
        // Google Books sometimes returns HTTP URLs, but iOS requires HTTPS
        // Replace http:// with https://
        if urlString.hasPrefix("http://") {
            return urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        
        return urlString
    }
    
    var isbn13: String? {
        volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
    }
    
    var isbn10: String? {
        volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
    }
    
    var suggestedTags: [String] {
        // Map Google's categories to our Tag enum
        guard let categories = volumeInfo.categories else { return [] }
        
        var tags: [String] = []
        
        for category in categories {
            let lowercased = category.lowercased()
            
            // Map common Google Books categories to our tags
            if lowercased.contains("fiction") && !lowercased.contains("non") {
                tags.append("literature")
            }
            if lowercased.contains("fantasy") {
                tags.append("fantasy")
            }
            if lowercased.contains("science fiction") || lowercased.contains("sci-fi") {
                tags.append("scifi")
            }
            if lowercased.contains("romance") {
                tags.append("romance")
            }
            if lowercased.contains("young adult") {
                tags.append("ya")
            }
            if lowercased.contains("horror") {
                tags.append("horror")
            }
            if lowercased.contains("history") {
                tags.append("history")
            }
            if lowercased.contains("mystery") || lowercased.contains("detective") {
                tags.append("mystery")
            }
            if lowercased.contains("thriller") || lowercased.contains("suspense") {
                tags.append("thriller")
            }
            if lowercased.contains("cooking") || lowercased.contains("recipe") {
                tags.append("cookbook")
            }
            if lowercased.contains("science") && !lowercased.contains("fiction") {
                tags.append("science")
            }
            if lowercased.contains("self-help") || lowercased.contains("self help") {
                tags.append("selfHelp")
            }
            if lowercased.contains("travel") {
                tags.append("travel")
            }
            if lowercased.contains("photography") {
                tags.append("photography")
            }
            if lowercased.contains("business") {
                tags.append("business")
            }
            if lowercased.contains("art") {
                tags.append("art")
            }
            if lowercased.contains("education") {
                tags.append("education")
            }
            if lowercased.contains("religion") {
                tags.append("religion")
            }
            if lowercased.contains("children") || lowercased.contains("juvenile") {
                tags.append("children")
            }
            if lowercased.contains("garden") {
                tags.append("gardening")
            }
            if lowercased.contains("fashion") {
                tags.append("fashion")
            }
            if lowercased.contains("beauty") {
                tags.append("beauty")
            }
            if lowercased.contains("design") {
                tags.append("design")
            }
            if lowercased.contains("non-fiction") || lowercased.contains("nonfiction") {
                tags.append("nonfiction")
            }
        }
        
        // Remove duplicates and return
        return Array(Set(tags))
    }
}

// MARK: - Google Books Service
@MainActor
class GoogleBooksService: ObservableObject {
    @Published var searchResults: [GoogleBookItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    // Smart query formatting to detect author vs title searches
    private func formatSearchQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let words = trimmed.split(separator: " ")
        
        // Heuristics to detect if this is likely an author name:
        // - 2-4 words (typical name length)
        // - First word is capitalized (proper noun)
        // - Doesn't contain common title words
        let commonTitleWords = ["the", "a", "an", "of", "and", "in", "on", "at", "to", "for"]
        let lowercasedQuery = trimmed.lowercased()
        let hasCommonTitleWord = commonTitleWords.contains { lowercasedQuery.contains($0) }
        
        let firstWordCapitalized = words.first?.first?.isUppercase ?? false
        let wordCount = words.count
        
        // If it looks like a person's name, use author search
        if wordCount >= 2 && wordCount <= 4 && firstWordCapitalized && !hasCommonTitleWord {
            return "inauthor:\(trimmed)"
        }
        
        // Otherwise, do a general search (searches title, author, description)
        return trimmed
    }
    
    // Search for books
    func searchBooks(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Smart search: format query to detect author vs title
        let searchQuery = formatSearchQuery(query)
        
        // Encode the query
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            errorMessage = "Invalid search query"
            isSearching = false
            return
        }
        
        // Build URL with query parameters
        let urlString = "\(baseURL)?q=\(encodedQuery)&maxResults=20&printType=books"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isSearching = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                errorMessage = "Server error: \(httpResponse.statusCode)"
                isSearching = false
                return
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            let result = try decoder.decode(GoogleBooksResponse.self, from: data)
            
            searchResults = result.items ?? []
            
            // Debug: Print first result's image URL
            if let firstBook = searchResults.first {
                print("📚 First book: \(firstBook.displayTitle)")
                print("🖼️ Image URL: \(firstBook.coverImageURL ?? "No image")")
                print("🔍 Search query used: \(searchQuery)")
            }
            
            if searchResults.isEmpty {
                errorMessage = "No books found"
            }
            
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            print("Error searching books: \(error)")
        }
        
        isSearching = false
    }
    
    // Get a single book by ID (for detailed view if needed)
    func getBook(id: String) async -> GoogleBookItem? {
        let urlString = "\(baseURL)/\(id)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let book = try decoder.decode(GoogleBookItem.self, from: data)
            return book
        } catch {
            print("Error fetching book: \(error)")
            return nil
        }
    }
}
