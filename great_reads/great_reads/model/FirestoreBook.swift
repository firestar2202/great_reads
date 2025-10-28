import Foundation
import FirebaseFirestore
import SwiftUI

struct FirestoreBook: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var tags: [String] // Store as strings for Firestore
    var userId: String
    var createdAt: Date
    
    // New fields from Google Books
    var description: String?
    var coverImageURL: String?
    var isbn: String?
    var pageCount: Int?
    var publishedDate: String?
    var publisher: String?
    var googleBooksId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case tags
        case userId
        case createdAt
        case description
        case coverImageURL
        case isbn
        case pageCount
        case publishedDate
        case publisher
        case googleBooksId
    }
    
    // Helper to convert tags to Tag enums
    var tagEnums: [Tag] {
        tags.compactMap { Tag(rawValue: $0) }
    }
    
    // Helper to get primary color (from first tag)
    var primaryColor: Color {
        tagEnums.first?.color ?? .blue
    }
}
