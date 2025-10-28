import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var bookManager = BookManager()
    
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
                AddBookView(bookManager: bookManager, userId: authManager.currentUserId ?? "")
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(isPresented: $showingAddFriend)
            }
            .onAppear {
                if let userId = authManager.currentUserId {
                    bookManager.fetchUserBooks(userId: userId)
                    
                    // Add example books only if user has none (checked in Firestore)
                    Task {
                        try? await bookManager.addExampleBooksIfNeeded(userId: userId)
                    }
                }
            }
            .onDisappear {
                bookManager.stopListening()
            }
        }
    }
    
    private func deleteBook(_ book: FirestoreBook) {
        Task {
            try? await bookManager.deleteBook(book)
        }
    }
}

// Book card component for Firestore books
struct FirestoreBookCard: View {
    let book: FirestoreBook
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(book.primaryColor.opacity(0.7))
                .frame(width: 60, height: 90)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title2)
                )
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // Tags
                if !book.tagEnums.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(book.tagEnums.prefix(3), id: \.self) { tag in
                            Text(tag.rawValue.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(tag.color)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Add Book view with Firestore
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    let bookManager: BookManager
    let userId: String
    
    @State private var title = ""
    @State private var author = ""
    @State private var selectedTags: Set<Tag> = []
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                }
                
                Section(header: Text("Tags (select up to 3)")) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Tag.allCases, id: \.self) { tag in
                            TagButton(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                onTap: {
                                    toggleTag(tag)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Add Book") {
                        addBook()
                    }
                    .disabled(title.isEmpty || author.isEmpty || selectedTags.isEmpty || isLoading)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(title.isEmpty || author.isEmpty || selectedTags.isEmpty ? .gray : .blue)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            if selectedTags.count < 3 {
                selectedTags.insert(tag)
            }
        }
    }
    
    private func addBook() {
        isLoading = true
        Task {
            let tagStrings = selectedTags.map { $0.rawValue }
            try? await bookManager.addBook(
                title: title,
                author: author,
                tags: tagStrings,
                userId: userId
            )
            isLoading = false
            dismiss()
        }
    }
}

// Tag button component
struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.rawValue.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : tag.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? tag.color : tag.color.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tag.color, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

// Placeholder for Add Friend view
struct AddFriendView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Friend Form")
                    .font(.title2)
                Text("(Coming soon)")
                    .foregroundColor(.gray)
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
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
