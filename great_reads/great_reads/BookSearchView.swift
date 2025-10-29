import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var googleBooks = GoogleBooksService()
    @ObservedObject var bookManager: BookManager
    let userId: String
    
    @State private var searchQuery = ""
    @State private var selectedBook: GoogleBookItem?
    @State private var showingBookDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by title or author", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await googleBooks.searchBooks(query: searchQuery)
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            googleBooks.searchResults = []
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
                
                // Search button
                Button(action: {
                    Task {
                        await googleBooks.searchBooks(query: searchQuery)
                    }
                }) {
                    Text("Search")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(searchQuery.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(searchQuery.isEmpty || googleBooks.isSearching)
                .padding(.horizontal)
                
                // Results
                if googleBooks.isSearching {
                    Spacer()
                    ProgressView("Searching books...")
                    Spacer()
                } else if let error = googleBooks.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if googleBooks.searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No books found")
                            .foregroundColor(.gray)
                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if !googleBooks.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(googleBooks.searchResults) { book in
                                BookSearchResultCard(book: book) {
                                    selectedBook = book
                                    showingBookDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Search for books")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Enter a title or author name above")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
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
            .sheet(isPresented: $showingBookDetail) {
                if let book = selectedBook {
                    BookDetailView(
                        book: book,
                        bookManager: bookManager,
                        userId: userId,
                        onSave: {
                            dismiss()
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Book Search Result Card
struct BookSearchResultCard: View {
    let book: GoogleBookItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover image
                if let imageURL = book.coverImageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
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
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 90)
                                .overlay(
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(6)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 90)
                        .overlay(
                            Image(systemName: "book.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Book info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.displayTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(book.displayAuthors)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if let date = book.volumeInfo.publishedDate {
                        Text(date)
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    // Show suggested tags
                    if !book.suggestedTags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(book.suggestedTags.prefix(2), id: \.self) { tagString in
                                if let tag = Tag(rawValue: tagString) {
                                    Text(tag.rawValue.capitalized)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(tag.color)
                                        .cornerRadius(3)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Detail View (for confirming and adding)
struct BookDetailView: View {
    let book: GoogleBookItem
    @ObservedObject var bookManager: BookManager
    let userId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTags: Set<String> = []
    @State private var isSaving = false
    
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
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
                    }
                    
                    // Book info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.displayTitle)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("by \(book.displayAuthors)")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        
                        if let publisher = book.volumeInfo.publisher,
                           let date = book.volumeInfo.publishedDate {
                            Text("\(publisher) • \(date)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        if let pageCount = book.volumeInfo.pageCount {
                            Text("\(pageCount) pages")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        if let description = book.volumeInfo.description {
                            Text("Description")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.top, 8)
                            
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Tag selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Tags (up to 3)")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Choose tags that describe this book")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Tag.allCases, id: \.self) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag.rawValue),
                                    isDisabled: !selectedTags.contains(tag.rawValue) && selectedTags.count >= 3
                                ) {
                                    toggleTag(tag.rawValue)
                                }
                            }
                        }
                    }
                    
                    // Save button
                    Button(action: saveBook) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Add to Library")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedTags.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedTags.isEmpty || isSaving)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-select suggested tags
                selectedTags = Set(book.suggestedTags.prefix(3))
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else if selectedTags.count < 3 {
            selectedTags.insert(tag)
        }
    }
    
    private func saveBook() {
        isSaving = true
        
        Task {
            do {
                try await bookManager.addBook(
                    title: book.displayTitle,
                    author: book.displayAuthors,
                    tags: Array(selectedTags),
                    userId: userId,
                    bookDescription: book.volumeInfo.description,
                    coverImageURL: book.coverImageURL,
                    isbn: book.isbn13 ?? book.isbn10,
                    pageCount: book.volumeInfo.pageCount,
                    publishedDate: book.volumeInfo.publishedDate,
                    publisher: book.volumeInfo.publisher,
                    googleBooksId: book.id
                )
                
                onSave()
            } catch {
                print("Error saving book: \(error)")
            }
            
            isSaving = false
        }
    }
}

// MARK: - Tag Button Component
struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.rawValue.capitalized)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : tag.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? tag.color : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(tag.color, lineWidth: isSelected ? 0 : 2)
                        )
                )
                .opacity(isDisabled ? 0.4 : 1.0)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    BookSearchView(bookManager: BookManager(), userId: "preview")
}
