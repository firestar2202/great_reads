import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        // Check if user is already logged in
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.user = result.user
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
    }
    
    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
    
    // Current user ID
    var currentUserId: String? {
        user?.uid
    }
}
