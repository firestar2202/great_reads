import SwiftUI

struct AddFriendView: View {
    @Binding var isPresented: Bool
    @ObservedObject var userManager: UserManager
    
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
                        .onSubmit { searchForUsers() }
                    
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
                    searchForUsers()
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
                    List(searchResults) { user in
                        UserRow(
                            user: user,
                            currentUserId: userManager.currentUser?.id,
                            isFriend: userManager.currentUser?.friends.contains(user.id ?? "") ?? false,
                            onAdd: { addFriend(user) }
                        )
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
        }
    }
    
    private func searchForUsers() {
        isSearching = true
        Task {
            do {
                searchResults = try await userManager.searchUsers(query: searchQuery)
                searchResults = searchResults.filter { $0.id != userManager.currentUser?.id }
            } catch {
                print("Error searching users: \(error)")
            }
            isSearching = false
        }
    }
    
    private func addFriend(_ user: FirestoreUser) {
        guard let friendId = user.id else { return }
        Task {
            try? await userManager.addFriend(friendId: friendId)
            searchResults.removeAll { $0.id == friendId }
        }
    }
}
