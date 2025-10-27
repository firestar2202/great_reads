import SwiftUI

// Book model
struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let vibe: String
    let coverColor: Color
}

struct ContentView: View {
    @State private var books: [Book] = [
        Book(title: "The Midnight Library", author: "Matt Haig", vibe: "Uplifting", coverColor: .blue),
        Book(title: "Project Hail Mary", author: "Andy Weir", vibe: "Thrilling", coverColor: .orange),
        Book(title: "Tomorrow, and Tomorrow, and Tomorrow", author: "Gabrielle Zevin", vibe: "Emotional", coverColor: .purple),
        Book(title: "The Seven Husbands of Evelyn Hugo", author: "Taylor Jenkins Reid", vibe: "Dramatic", coverColor: .pink),
        Book(title: "Anxious People", author: "Fredrik Backman", vibe: "Cozy", coverColor: .green),
        Book(title: "The Silent Patient", author: "Alex Michaelides", vibe: "Dark", coverColor: .black),
        Book(title: "Educated", author: "Tara Westover", vibe: "Inspiring", coverColor: .yellow),
        Book(title: "Where the Crawdads Sing", author: "Delia Owens", vibe: "Atmospheric", coverColor: .teal),
        Book(title: "The House in the Cerulean Sea", author: "TJ Klune", vibe: "Wholesome", coverColor: .cyan),
        Book(title: "Mexican Gothic", author: "Silvia Moreno-Garcia", vibe: "Eerie", coverColor: .red)
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
                .fill(book.coverColor.opacity(0.7))
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
                
                // Vibe tag
                Text(book.vibe)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(book.coverColor.opacity(0.8))
                    .cornerRadius(6)
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
