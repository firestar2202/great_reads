import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class UserManager: ObservableObject {
    @Published var currentUser: FirestoreUser?
    @Published var friends: [FirestoreUser] = []
    
    private let db = Firestore.firestore()
    
    // Create user profile on signup
    func createUserProfile(userId: String, email: String, username: String) async throws {
        let user = FirestoreUser(
            id: userId,
            username: username,
            email: email,
            createdAt: Date(),
            friends: []
        )
        
        try db.collection("users").document(userId).setData(from: user)
        self.currentUser = user
    }
    
    // Fetch current user profile
    func fetchUserProfile(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        self.currentUser = try document.data(as: FirestoreUser.self)
    }
    
    // Search for users by username
    func searchUsers(query: String) async throws -> [FirestoreUser] {
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: FirestoreUser.self)
        }
    }
    
    // Add a friend
    func addFriend(friendId: String) async throws {
        guard let currentUserId = currentUser?.id else { return }
        
        // Add friend to current user's friends list
        try await db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
        
        // Add current user to friend's friends list (mutual)
        try await db.collection("users").document(friendId).updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ])
        
        // Refresh current user
        try await fetchUserProfile(userId: currentUserId)
        try await fetchFriends()
    }
    
    // Remove a friend
    func removeFriend(friendId: String) async throws {
        guard let currentUserId = currentUser?.id else { return }
        
        // Remove friend from current user's friends list
        try await db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayRemove([friendId])
        ])
        
        // Remove current user from friend's friends list
        try await db.collection("users").document(friendId).updateData([
            "friends": FieldValue.arrayRemove([currentUserId])
        ])
        
        // Refresh
        try await fetchUserProfile(userId: currentUserId)
        try await fetchFriends()
    }
    
    // Fetch all friends
    func fetchFriends() async throws {
        guard let friendIds = currentUser?.friends, !friendIds.isEmpty else {
            self.friends = []
            return
        }
        
        // Firestore 'in' queries are limited to 10 items at a time
        let snapshot = try await db.collection("users")
            .whereField(FieldPath.documentID(), in: friendIds)
            .getDocuments()
        
        self.friends = snapshot.documents.compactMap { doc in
            try? doc.data(as: FirestoreUser.self)
        }
    }
    
    // Get a specific user by ID
    func getUser(userId: String) async throws -> FirestoreUser? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try? document.data(as: FirestoreUser.self)
    }
    
    // Check if username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    // Get email from username (for login)
    func getEmailFromUsername(_ username: String) async throws -> String? {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        let user = try document.data(as: FirestoreUser.self)
        return user.email
    }
}
