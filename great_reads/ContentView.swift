import SwiftUI

// MARK: - Books View
struct BooksView: View {
    @ObservedObject var bookManager: BookManager
    @ObservedObject var userManager: UserManager
    @ObservedObject var authManager: AuthManager
    
    @State private var showingAddBook = false
    @State private var showingAddFriend = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showingAddBook = true
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Add Book")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Friend")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding()
                
                // Books list
                if bookManager.books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No books yet!")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap 'Add Book' to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bookManager.books) { book in
                                FirestoreBookCard(book: book, onDelete: {
                                    deleteBook(book)
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        try? authManager.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                BookSearchView(bookManager: bookManager, userId: authManager.currentUserId ?? "")
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(isPresented: $showingAddFriend, userManager: userManager)
            }
        }
    }
    
    private func deleteBook(_ book: FirestoreBook) {
        Task {
            try? await bookManager.deleteBook(book)
        }
    }
}

// MARK: - Feed View
struct FeedView: View {
    @ObservedObject var userManager: UserManager
    @StateObject private var feedManager = FeedManager()
    @State private var selectedFriend: FirestoreUser?
    @State private var showingFriendProfile = false
    @State private var friendBookManagers: [String: BookManager] = [:] // Store book managers by friend ID
    
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

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var bookManager = BookManager()
    @StateObject private var userManager = UserManager()
    
    var body: some View {
        TabView {
            BooksView(bookManager: bookManager, userManager: userManager, authManager: authManager)
                .tabItem {
                    Label("Books", systemImage: "book.fill")
                }
            
            FriendsListView(userManager: userManager)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            FeedView(userManager: userManager)
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
            
            VibeView(userManager: userManager)
                .tabItem {
                    Label("My Vibe", systemImage: "sparkles")
                }
        }
        .onAppear {
            if let userId = authManager.currentUserId {
                bookManager.fetchUserBooks(userId: userId)
                
                Task {
                    try? await userManager.fetchUserProfile(userId: userId)
                }
                
                Task {
                    try? await bookManager.addExampleBooksIfNeeded(userId: userId)
                }
            }
        }
    }
}

// MARK: - Book Card (NO TAGS)
struct FirestoreBookCard: View {
    let book: FirestoreBook
    let onDelete: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
            // Cover image or placeholder
            if let imageURL = book.coverImageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 60, height: 90)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 60, height: 90)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.title2)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Fallback placeholder for books without images
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 60, height: 90)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.title2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                if let dateReadText = book.formattedDateRead {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(dateReadText)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            BookDetailSheet(book: book)
        }
    }
}

// MARK: - Book Detail Sheet
struct BookDetailSheet: View {
    let book: FirestoreBook
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover image
                    if let imageURL = book.coverImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                            default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(height: 300)
                                    .overlay(
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Book info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("by \(book.author)")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        
                        if let dateReadText = book.formattedDateRead {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Read on \(dateReadText)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    if let description = book.bookDescription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(description)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    if let review = book.review, !review.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Review")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(review)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Friend View
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

// MARK: - User Row
struct UserRow: View {
    let user: FirestoreUser
    let currentUserId: String?
    let isFriend: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(user.email)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isFriend {
                Text("Friends")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activity Card (NO TAGS)
struct ActivityCard: View {
    let item: ActivityItem
    let onTapUser: () -> Void
    @State private var showingBookDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info header
            HStack {
                Button(action: onTapUser) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(item.user?.username.prefix(1).uppercased() ?? "?")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.user?.username ?? "Unknown")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(item.timeAgo)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Text("added")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Book info
            Button(action: {
                showingBookDetail = true
            }) {
                HStack(spacing: 12) {
                    // Cover image or placeholder
                    if let imageURL = item.book.coverImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 50, height: 75)
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 75)
                                    .clipped()
                                    .cornerRadius(6)
                            case .failure:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 50, height: 75)
                                    .overlay(
                                        Image(systemName: "book.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.title3)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Fallback placeholder for books without images
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 50, height: 75)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.title3)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.book.title)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Text("by \(item.book.author)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        if let dateReadText = item.book.formattedDateRead {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                                Text(dateReadText)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 2)
                        }
                        
                        if let review = item.book.review, !review.isEmpty {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                                Text(firstSentence(of: review))
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingBookDetail) {
            FeedBookDetailSheet(book: item.book, user: item.user)
        }
    }
    
    private func firstSentence(of text: String) -> String {
        // Find the first sentence (ending with . ! or ?)
        let sentenceEndings: Set<Character> = [".", "!", "?"]
        
        if let endIndex = text.firstIndex(where: { sentenceEndings.contains($0) }) {
            let sentence = text[...endIndex]
            return String(sentence).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no sentence ending found, return first 100 characters
        let preview = String(text.prefix(100))
        return preview.trimmingCharacters(in: .whitespacesAndNewlines) + (text.count > 100 ? "..." : "")
    }
}

// MARK: - Feed Book Detail Sheet
struct FeedBookDetailSheet: View {
    let book: FirestoreBook
    let user: FirestoreUser?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover image
                    if let imageURL = book.coverImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                            default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(height: 300)
                                    .overlay(
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Book info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("by \(book.author)")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        
                        if let dateReadText = book.formattedDateRead {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Read on \(dateReadText)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        
                        if let username = user?.username {
                            HStack(spacing: 6) {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text("Added by \(username)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    if let description = book.bookDescription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(description)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    if let review = book.review, !review.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if let username = user?.username {
                                Text("\(username)'s Review")
                                    .font(.system(size: 18, weight: .semibold))
                            } else {
                                Text("Review")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            
                            Text(review)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
