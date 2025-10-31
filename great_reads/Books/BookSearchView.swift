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
    @State private var isSaving = false
    @State private var dateRead = Date()
    @State private var showDatePicker = false
    @State private var review = ""
    
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
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Date Read Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When did you read this?")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                
                                Text(formatDate(dateRead))
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        if showDatePicker {
                            DatePicker(
                                "Select Date",
                                selection: $dateRead,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Review Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Review (Optional)")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Share your thoughts about this book")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .topLeading) {
                            if review.isEmpty {
                                Text("What did you think? Any favorite moments, characters, or quotes?")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $review)
                                .font(.system(size: 15))
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isSaving)
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
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func saveBook() {
        isSaving = true
        
        Task {
            do {
                try await bookManager.addBook(
                    title: book.displayTitle,
                    author: book.displayAuthors,
                    tags: [], // Empty array since we're not using tags
                    userId: userId,
                    bookDescription: book.volumeInfo.description,
                    coverImageURL: book.coverImageURL,
                    isbn: book.isbn13 ?? book.isbn10,
                    pageCount: book.volumeInfo.pageCount,
                    publishedDate: book.volumeInfo.publishedDate,
                    publisher: book.volumeInfo.publisher,
                    googleBooksId: book.id,
                    dateRead: dateRead,
                    review: review.isEmpty ? nil : review
                )
                
                onSave()
            } catch {
                print("Error saving book: \(error)")
            }
            
            isSaving = false
        }
    }
}

#Preview {
    BookSearchView(bookManager: BookManager(), userId: "preview")
}
