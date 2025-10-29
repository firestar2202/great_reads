import Foundation
import FirebaseFirestore

struct FirestoreUser: Codable, Identifiable {
    @DocumentID var id: String? // This will be the Firebase Auth UID
    var username: String
    var email: String
    var createdAt: Date
    var friends: [String] // Array of friend user IDs
    var currentVibe: String? // AI-generated vibe text
    var vibeGeneratedAt: Date? // When vibe was last generated
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt
        case friends
        case currentVibe
        case vibeGeneratedAt
    }
}
