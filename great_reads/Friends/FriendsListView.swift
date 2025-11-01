//
//  FriendsListView.swift
//  great_reads
//
//  Created by Justin Haddad on 10/28/25.
//


import SwiftUI

struct FriendsListView: View {
    @ObservedObject var userManager: UserManager
    @ObservedObject var authManager: AuthManager
    @State private var selectedFriend: FirestoreUser?
    @State private var showingFriendProfile = false
    @State private var friendBookManagers: [String: BookManager] = [:] // Store book managers by friend ID
    @State private var pendingRequests: [FirestoreUser] = [] // Incoming requests
    @State private var outgoingRequests: [FirestoreUser] = [] // Outgoing requests
    @State private var friendToRemove: FirestoreUser?
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                if userManager.friends.isEmpty && pendingRequests.isEmpty && outgoingRequests.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No friends yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap 'Add Friend' to find people")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Incoming pending requests section
                        if !pendingRequests.isEmpty {
                            Section(header: Text("Pending Requests (\(pendingRequests.count))")) {
                                ForEach(pendingRequests) { user in
                                    HStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(user.username.prefix(1).uppercased())
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundColor(.orange)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.username)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Text("Wants to be friends")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button {
                                                declineRequest(from: user)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.red.opacity(0.1))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Button {
                                                acceptRequest(from: user)
                                            } label: {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.green)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.green.opacity(0.1))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Outgoing requests section
                        if !outgoingRequests.isEmpty {
                            Section(header: Text("Outgoing Requests (\(outgoingRequests.count))")) {
                                ForEach(outgoingRequests) { user in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Text(user.username.prefix(1).uppercased())
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundColor(.blue)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.username)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Text("Request sent")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            cancelOutgoingRequest(to: user)
                                        }) {
                                            Text("Cancel")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Friends section
                        if !userManager.friends.isEmpty {
                            Section(header: Text("Friends (\(userManager.friends.count))")) {
                                ForEach(userManager.friends) { friend in
                                    HStack {
                                        Button(action: {
                                            selectedFriend = friend
                                            showingFriendProfile = true
                                        }) {
                                            FriendRow(friend: friend)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            friendToRemove = friend
                                            showingRemoveConfirmation = true
                                        }) {
                                            Image(systemName: "person.fill.xmark")
                                                .foregroundColor(.red)
                                                .font(.system(size: 16))
                                                .padding(8)
                                                .background(Color.red.opacity(0.1))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .sheet(item: $selectedFriend) { friend in
                let bookManager = getOrCreateBookManager(for: friend)
                FriendProfileView(
                    friend: friend,
                    userManager: userManager,
                    bookManager: bookManager
                )
            }
            .onAppear {
                Task {
                    // Ensure current user is loaded first
                    if userManager.currentUser == nil, let userId = authManager.currentUserId {
                        try? await userManager.fetchUserProfile(userId: userId)
                    }
                    
                    try? await userManager.fetchFriends()
                    pendingRequests = try await userManager.fetchReceivedFriendRequests()
                    outgoingRequests = try await userManager.fetchSentFriendRequests()
                    
                    // Preload books for all friends
                    for friend in userManager.friends {
                        if let friendId = friend.id,
                           friendBookManagers[friendId] == nil {
                            let bookManager = BookManager()
                            friendBookManagers[friendId] = bookManager
                            bookManager.fetchUserBooks(userId: friendId)
                        }
                    }
                }
            }
            .refreshable {
                Task {
                    // Ensure current user is loaded first
                    if userManager.currentUser == nil, let userId = authManager.currentUserId {
                        try? await userManager.fetchUserProfile(userId: userId)
                    }
                    
                    try? await userManager.fetchFriends()
                    pendingRequests = try await userManager.fetchReceivedFriendRequests()
                    outgoingRequests = try await userManager.fetchSentFriendRequests()
                }
            }
            .alert("Remove Friend", isPresented: $showingRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        removeFriend(friend)
                    }
                }
            } message: {
                if let friend = friendToRemove {
                    Text("Are you sure you want to remove \(friend.username) as a friend?")
                }
            }
        }
    }
    
    private func getOrCreateBookManager(for friend: FirestoreUser) -> BookManager {
        guard let friendId = friend.id else {
            return BookManager()
        }
        
        if let existing = friendBookManagers[friendId] {
            return existing
        }
        
        let bookManager = BookManager()
        friendBookManagers[friendId] = bookManager
        bookManager.fetchUserBooks(userId: friendId)
        return bookManager
    }
    
    private func removeFriend(_ friend: FirestoreUser) {
        guard let friendId = friend.id else { return }
        
        // Stop listening and remove book manager
        friendBookManagers[friendId]?.stopListening()
        friendBookManagers.removeValue(forKey: friendId)
        
        Task {
            try? await userManager.removeFriend(friendId: friendId)
            
            // Refresh friends list
            try? await userManager.fetchFriends()
        }
    }
    
    private func acceptRequest(from user: FirestoreUser) {
        guard let userId = user.id else { return }
        Task {
            try? await userManager.acceptFriendRequest(from: userId)
            
            // Refresh friends list and all requests
            try? await userManager.fetchFriends()
            pendingRequests = try await userManager.fetchReceivedFriendRequests()
            outgoingRequests = try await userManager.fetchSentFriendRequests()
            
            // Preload books for the new friend
            if friendBookManagers[userId] == nil {
                let bookManager = BookManager()
                friendBookManagers[userId] = bookManager
                bookManager.fetchUserBooks(userId: userId)
            }
        }
    }
    
    private func declineRequest(from user: FirestoreUser) {
        guard let userId = user.id else { return }
        Task {
            try? await userManager.declineFriendRequest(from: userId)
            
            // Refresh pending requests
            pendingRequests = try await userManager.fetchReceivedFriendRequests()
        }
    }
    
    private func cancelOutgoingRequest(to user: FirestoreUser) {
        guard let userId = user.id else { return }
        Task {
            try? await userManager.cancelFriendRequest(to: userId)
            
            // Refresh outgoing requests
            outgoingRequests = try await userManager.fetchSentFriendRequests()
        }
    }
}

// Friend row component
struct FriendRow: View {
    let friend: FirestoreUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.username)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Tap to view books")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FriendsListView(userManager: UserManager(), authManager: AuthManager())
}
