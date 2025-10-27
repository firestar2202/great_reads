import SwiftUI

struct ContentView: View {
    @State private var books: [Book] = [
        Book(title: "The Midnight Library", author: "Matt Haig", tags: [.thriller, .history]),
        Book(title: "Project Hail Mary", author: "Andy Weir", tags: [.scifi, .ya]),
    ]
    
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(books) { book in
                            BookCard(book: book)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Books")
            .sheet(isPresented: $showingAddBook) {
                AddBookView(isPresented: $showingAddBook)
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(isPresented: $showingAddFriend)
            }
        }
    }
}

// Book card component
struct BookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(book.tags.first?.color.opacity(0.7) ?? Color.gray.opacity(0.7))
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
                HStack(spacing: 4) {
                    ForEach(book.tags, id: \.self) { tag in
                        Text(tag.rawValue.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tag.color.opacity(0.8))
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Placeholder for Add Book view
struct AddBookView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Book Form")
                    .font(.title2)
                Text("(Coming soon)")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Add Book")
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
}
