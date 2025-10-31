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
            friends: [],
            sentFriendRequests: [],
            receivedFriendRequests: []
        )
        
        try db.collection("users").document(userId).setData(from: user)
        self.currentUser = user
    }
    
    // Fetch current user profile
    func fetchUserProfile(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        var user = try document.data(as: FirestoreUser.self)
        // Ensure @DocumentID is set from document ID
        user.id = document.documentID
        self.currentUser = user
    }
    
    // Search for users by username
    func searchUsers(query: String) async throws -> [FirestoreUser] {
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()
        
        let currentUserId = currentUser?.id
        
        var results: [FirestoreUser] = []
        for doc in snapshot.documents {
            // Filter out current user
            if doc.documentID == currentUserId {
                continue
            }
            
            do {
                var user = try doc.data(as: FirestoreUser.self)
                // Ensure @DocumentID is set from document ID
                user.id = doc.documentID
                results.append(user)
            } catch {
                // Try to decode with defaults for missing fields
                if let data = doc.data() as? [String: Any] {
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let friends = data["friends"] as? [String] ?? []
                    let sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
                    let receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
                    
                    let user = FirestoreUser(
                        id: doc.documentID,
                        username: username,
                        email: email,
                        createdAt: createdAt,
                        friends: friends,
                        sentFriendRequests: sentFriendRequests,
                        receivedFriendRequests: receivedFriendRequests,
                        currentVibe: data["currentVibe"] as? String,
                        vibeGeneratedAt: (data["vibeGeneratedAt"] as? Timestamp)?.dateValue()
                    )
                    results.append(user)
                }
            }
        }
        return results
    }
    
    // Send a friend request
    func sendFriendRequest(to friendId: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Add to current user's sent requests
        try await db.collection("users").document(currentUserId).updateData([
            "sentFriendRequests": FieldValue.arrayUnion([friendId])
        ])
        
        // Add to friend's received requests
        try await db.collection("users").document(friendId).updateData([
            "receivedFriendRequests": FieldValue.arrayUnion([currentUserId])
        ])
        
        // Refresh current user
        try await fetchUserProfile(userId: currentUserId)
    }
    
    // Accept a friend request
    func acceptFriendRequest(from friendId: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Remove from current user's received requests
        try await db.collection("users").document(currentUserId).updateData([
            "receivedFriendRequests": FieldValue.arrayRemove([friendId])
        ])
        
        // Remove from friend's sent requests
        try await db.collection("users").document(friendId).updateData([
            "sentFriendRequests": FieldValue.arrayRemove([currentUserId])
        ])
        
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
    
    // Decline a friend request
    func declineFriendRequest(from friendId: String) async throws {
        guard let currentUserId = currentUser?.id else { return }
        
        // Remove from current user's received requests
        try await db.collection("users").document(currentUserId).updateData([
            "receivedFriendRequests": FieldValue.arrayRemove([friendId])
        ])
        
        // Remove from friend's sent requests
        try await db.collection("users").document(friendId).updateData([
            "sentFriendRequests": FieldValue.arrayRemove([currentUserId])
        ])
        
        // Refresh current user
        try await fetchUserProfile(userId: currentUserId)
    }
    
    // Cancel a sent friend request
    func cancelFriendRequest(to friendId: String) async throws {
        guard let currentUserId = currentUser?.id else { return }
        
        // Remove from current user's sent requests
        try await db.collection("users").document(currentUserId).updateData([
            "sentFriendRequests": FieldValue.arrayRemove([friendId])
        ])
        
        // Remove from friend's received requests
        try await db.collection("users").document(friendId).updateData([
            "receivedFriendRequests": FieldValue.arrayRemove([currentUserId])
        ])
        
        // Refresh current user
        try await fetchUserProfile(userId: currentUserId)
    }
    
    // Legacy method - kept for backwards compatibility but should use sendFriendRequest instead
    func addFriend(friendId: String) async throws {
        // This is now deprecated - use sendFriendRequest instead
        try await sendFriendRequest(to: friendId)
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
        
        var results: [FirestoreUser] = []
        for doc in snapshot.documents {
            do {
                var user = try doc.data(as: FirestoreUser.self)
                // Ensure @DocumentID is set from document ID
                user.id = doc.documentID
                results.append(user)
            } catch {
                // Try to decode with defaults for missing fields
                if let data = doc.data() as? [String: Any] {
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let friends = data["friends"] as? [String] ?? []
                    let sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
                    let receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
                    
                    let user = FirestoreUser(
                        id: doc.documentID,
                        username: username,
                        email: email,
                        createdAt: createdAt,
                        friends: friends,
                        sentFriendRequests: sentFriendRequests,
                        receivedFriendRequests: receivedFriendRequests,
                        currentVibe: data["currentVibe"] as? String,
                        vibeGeneratedAt: (data["vibeGeneratedAt"] as? Timestamp)?.dateValue()
                    )
                    results.append(user)
                }
            }
        }
        // Remove duplicates based on ID, preserving order
        var seenIds = Set<String>()
        self.friends = results.filter { user in
            guard let id = user.id, !id.isEmpty else { return false }
            if seenIds.contains(id) {
                return false
            }
            seenIds.insert(id)
            return true
        }
    }
    
    // Fetch users who received friend requests from current user
    func fetchSentFriendRequests() async throws -> [FirestoreUser] {
        guard let sentRequestIds = currentUser?.sentFriendRequests, !sentRequestIds.isEmpty else {
            return []
        }
        
        let snapshot = try await db.collection("users")
            .whereField(FieldPath.documentID(), in: sentRequestIds)
            .getDocuments()
        
        var results: [FirestoreUser] = []
        for doc in snapshot.documents {
            do {
                var user = try doc.data(as: FirestoreUser.self)
                // Ensure @DocumentID is set from document ID
                user.id = doc.documentID
                results.append(user)
            } catch {
                // Try to decode with defaults for missing fields
                if let data = doc.data() as? [String: Any] {
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let friends = data["friends"] as? [String] ?? []
                    let sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
                    let receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
                    
                    let user = FirestoreUser(
                        id: doc.documentID,
                        username: username,
                        email: email,
                        createdAt: createdAt,
                        friends: friends,
                        sentFriendRequests: sentFriendRequests,
                        receivedFriendRequests: receivedFriendRequests,
                        currentVibe: data["currentVibe"] as? String,
                        vibeGeneratedAt: (data["vibeGeneratedAt"] as? Timestamp)?.dateValue()
                    )
                    results.append(user)
                }
            }
        }
        // Remove duplicates based on ID, preserving order
        var seenIds = Set<String>()
        return results.filter { user in
            guard let id = user.id, !id.isEmpty else { return false }
            if seenIds.contains(id) {
                return false
            }
            seenIds.insert(id)
            return true
        }
    }
    
    // Fetch users who sent friend requests to current user
    func fetchReceivedFriendRequests() async throws -> [FirestoreUser] {
        guard let receivedRequestIds = currentUser?.receivedFriendRequests, !receivedRequestIds.isEmpty else {
            return []
        }
        
        let snapshot = try await db.collection("users")
            .whereField(FieldPath.documentID(), in: receivedRequestIds)
            .getDocuments()
        
        var results: [FirestoreUser] = []
        for doc in snapshot.documents {
            do {
                var user = try doc.data(as: FirestoreUser.self)
                // Ensure @DocumentID is set from document ID
                user.id = doc.documentID
                results.append(user)
            } catch {
                // Try to decode with defaults for missing fields
                if let data = doc.data() as? [String: Any] {
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let friends = data["friends"] as? [String] ?? []
                    let sentFriendRequests = data["sentFriendRequests"] as? [String] ?? []
                    let receivedFriendRequests = data["receivedFriendRequests"] as? [String] ?? []
                    
                    let user = FirestoreUser(
                        id: doc.documentID,
                        username: username,
                        email: email,
                        createdAt: createdAt,
                        friends: friends,
                        sentFriendRequests: sentFriendRequests,
                        receivedFriendRequests: receivedFriendRequests,
                        currentVibe: data["currentVibe"] as? String,
                        vibeGeneratedAt: (data["vibeGeneratedAt"] as? Timestamp)?.dateValue()
                    )
                    results.append(user)
                }
            }
        }
        // Remove duplicates based on ID, preserving order
        var seenIds = Set<String>()
        return results.filter { user in
            guard let id = user.id, !id.isEmpty else { return false }
            if seenIds.contains(id) {
                return false
            }
            seenIds.insert(id)
            return true
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
