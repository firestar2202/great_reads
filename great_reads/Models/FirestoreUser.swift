import Foundation
import FirebaseFirestore

struct FirestoreUser: Codable, Identifiable {
    @DocumentID var id: String? // This will be the Firebase Auth UID
    var username: String
    var email: String
    var createdAt: Date
    var friends: [String] // Array of friend user IDs
    var sentFriendRequests: [String] // Users I've sent friend requests to
    var receivedFriendRequests: [String] // Users who sent me friend requests
    var currentVibe: String? // AI-generated vibe text
    var vibeGeneratedAt: Date? // When vibe was last generated
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt
        case friends
        case sentFriendRequests
        case receivedFriendRequests
        case currentVibe
        case vibeGeneratedAt
    }
    
    init(id: String? = nil, username: String, email: String, createdAt: Date, friends: [String] = [], sentFriendRequests: [String] = [], receivedFriendRequests: [String] = [], currentVibe: String? = nil, vibeGeneratedAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
        self.friends = friends
        self.sentFriendRequests = sentFriendRequests
        self.receivedFriendRequests = receivedFriendRequests
        self.currentVibe = currentVibe
        self.vibeGeneratedAt = vibeGeneratedAt
    }
    
    // Custom decoder to handle missing fields in existing documents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Don't decode id at all - @DocumentID property wrapper handles it automatically
        // Firestore will set it from the document ID even with a custom decoder
        id = nil
        
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        friends = try container.decodeIfPresent([String].self, forKey: .friends) ?? []
        sentFriendRequests = try container.decodeIfPresent([String].self, forKey: .sentFriendRequests) ?? []
        receivedFriendRequests = try container.decodeIfPresent([String].self, forKey: .receivedFriendRequests) ?? []
        currentVibe = try container.decodeIfPresent(String.self, forKey: .currentVibe)
        vibeGeneratedAt = try container.decodeIfPresent(Date.self, forKey: .vibeGeneratedAt)
    }
}
