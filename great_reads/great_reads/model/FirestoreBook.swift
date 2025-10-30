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
    var bookDescription: String?
    var coverImageURL: String?
    var isbn: String?
    var pageCount: Int?
    var publishedDate: String?
    var publisher: String?
    var googleBooksId: String?
    
    // Date read field
    var dateRead: Date?
    
    // Review field
    var review: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case tags
        case userId
        case createdAt
        case bookDescription
        case coverImageURL
        case isbn
        case pageCount
        case publishedDate
        case publisher
        case googleBooksId
        case dateRead
        case review
    }
    
    // Helper to convert tags to Tag enums
    var tagEnums: [Tag] {
        tags.compactMap { Tag(rawValue: $0) }
    }
    
    // Helper to get primary color (from first tag)
    var primaryColor: Color {
        tagEnums.first?.color ?? .blue
    }
    
    // Helper to format date read
    var formattedDateRead: String? {
        guard let dateRead = dateRead else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateRead)
    }
}
