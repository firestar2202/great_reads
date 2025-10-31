//
//  FriendsListView.swift
//  great_reads
//
//  Created by Justin Haddad on 10/28/25.
//


import SwiftUI

struct FriendsListView: View {
    @ObservedObject var userManager: UserManager
    @State private var selectedFriend: FirestoreUser?
    @State private var showingFriendProfile = false
    @State private var friendBookManagers: [String: BookManager] = [:] // Store book managers by friend ID
    
    var body: some View {
        NavigationView {
            VStack {
                if userManager.friends.isEmpty {
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
                    List(userManager.friends) { friend in
                        Button(action: {
                            selectedFriend = friend
                            showingFriendProfile = true
                        }) {
                            FriendRow(friend: friend)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                removeFriend(friend)
                            } label: {
                                Label("Remove", systemImage: "person.fill.xmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends (\(userManager.friends.count))")
            .sheet(isPresented: $showingFriendProfile) {
                if let friend = selectedFriend,
                   let bookManager = friendBookManagers[friend.id ?? ""] {
                    FriendProfileView(
                        friend: friend,
                        userManager: userManager,
                        bookManager: bookManager
                    )
                }
            }
            .onAppear {
                Task {
                    try? await userManager.fetchFriends()
                    
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
        }
    }
    
    private func removeFriend(_ friend: FirestoreUser) {
        guard let friendId = friend.id else { return }
        
        // Stop listening and remove book manager
        friendBookManagers[friendId]?.stopListening()
        friendBookManagers.removeValue(forKey: friendId)
        
        Task {
            try? await userManager.removeFriend(friendId: friendId)
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
    FriendsListView(userManager: UserManager())
}
