import SwiftUI

struct FeedView: View {
    @ObservedObject var userManager: UserManager
    @StateObject private var feedManager = FeedManager()
    @State private var selectedFriend: FirestoreUser?
    @State private var showingFriendProfile = false
    @State private var friendBookManagers: [String: BookManager] = [:]
    
    var body: some View {
        NavigationView {
            Group {
                if feedManager.isLoading {
                    ProgressView()
                } else if feedManager.activityItems.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Activity Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Add friends to see what they're reading!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(feedManager.activityItems) { item in
                                ActivityCard(
                                    item: item,
                                    onTapUser: {
                                        if let friend = item.user {
                                            selectedFriend = friend
                                            showingFriendProfile = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        if let friendIds = userManager.currentUser?.friends {
                            await feedManager.fetchFriendActivity(friendIds: friendIds)
                        }
                    }
                }
            }
            .navigationTitle("Feed")
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
                if let friendIds = userManager.currentUser?.friends {
                    Task {
                        await feedManager.fetchFriendActivity(friendIds: friendIds)
                        
                        // Preload books for all friends
                        for friendId in friendIds {
                            if friendBookManagers[friendId] == nil {
                                let bookManager = BookManager()
                                friendBookManagers[friendId] = bookManager
                                bookManager.fetchUserBooks(userId: friendId)
                            }
                        }
                    }
                }
            }
        }
    }
}
