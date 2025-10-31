import SwiftUI

struct AddFriendView: View {
    @Binding var isPresented: Bool
    @ObservedObject var userManager: UserManager
    @ObservedObject var authManager: AuthManager
    
    @State private var searchQuery = ""
    @State private var searchResults: [FirestoreUser] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by username", text: $searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { 
                            Task { await searchForUsers() }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                Button("Search") {
                    Task { await searchForUsers() }
                }
                .disabled(searchQuery.isEmpty || isSearching)
                .padding(.horizontal)
                
                if isSearching {
                    ProgressView().padding()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No users found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { user in
                            UserRow(
                                user: user,
                                currentUserId: userManager.currentUser?.id,
                                friendStatus: getFriendStatus(for: user),
                                onAdd: { sendFriendRequest(to: user) },
                                onAccept: { acceptFriendRequest(from: user) },
                                onDecline: { declineFriendRequest(from: user) },
                                onCancel: { cancelFriendRequest(to: user) }
                            )
                            .id("\(user.id ?? "")-\(userManager.currentUser?.sentFriendRequests.contains(user.id ?? "") ?? false)")
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                // Ensure current user is loaded when view appears
                Task {
                    if let userId = authManager.currentUserId {
                        if userManager.currentUser == nil || userManager.currentUser?.id != userId {
                            try? await userManager.fetchUserProfile(userId: userId)
                        }
                    }
                }
            }
        }
    }
    
    private func searchForUsers() async {
        await MainActor.run {
            isSearching = true
        }
        
        do {
            // Ensure current user is loaded
            if userManager.currentUser == nil, let userId = authManager.currentUserId {
                try? await userManager.fetchUserProfile(userId: userId)
            } else if let userId = userManager.currentUser?.id ?? authManager.currentUserId {
                // Refresh current user profile to get latest friend request status
                try? await userManager.fetchUserProfile(userId: userId)
            }
            
            let results = try await userManager.searchUsers(query: searchQuery)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
    
    private func getFriendStatus(for user: FirestoreUser) -> FriendStatus {
        guard let userId = user.id,
              let currentUser = userManager.currentUser else {
            return .notFriend
        }
        
        if currentUser.friends.contains(userId) {
            return .friend
        } else if currentUser.sentFriendRequests.contains(userId) {
            return .pendingSent
        } else if currentUser.receivedFriendRequests.contains(userId) {
            return .pendingReceived
        } else {
            return .notFriend
        }
    }
    
    private func sendFriendRequest(to user: FirestoreUser) {
        guard let friendId = user.id else { return }
        Task {
            do {
                // Ensure current user is loaded before sending request
                if userManager.currentUser == nil {
                    guard let userId = authManager.currentUserId else { return }
                    try await userManager.fetchUserProfile(userId: userId)
                }
                
                // Ensure user ID is set (fallback to authManager if needed)
                if userManager.currentUser?.id == nil {
                    if let authUserId = authManager.currentUserId {
                        try await userManager.fetchUserProfile(userId: authUserId)
                    } else {
                        return
                    }
                }
                
                try await userManager.sendFriendRequest(to: friendId)
                
                // Refresh user profile to update friend request status
                // The UI will automatically update since userManager.currentUser is @Published
                if let userId = userManager.currentUser?.id {
                    try await userManager.fetchUserProfile(userId: userId)
                }
            } catch {
                // Silently handle errors - UI will show current state
            }
        }
    }
    
    private func acceptFriendRequest(from user: FirestoreUser) {
        guard let friendId = user.id else { return }
        Task {
            try? await userManager.acceptFriendRequest(from: friendId)
            // UI will automatically update since userManager.currentUser is @Published
        }
    }
    
    private func declineFriendRequest(from user: FirestoreUser) {
        guard let friendId = user.id else { return }
        Task {
            try? await userManager.declineFriendRequest(from: friendId)
            // UI will automatically update since userManager.currentUser is @Published
        }
    }
    
    private func cancelFriendRequest(to user: FirestoreUser) {
        guard let friendId = user.id else { return }
        Task {
            try? await userManager.cancelFriendRequest(to: friendId)
            // UI will automatically update since userManager.currentUser is @Published
        }
    }
}
