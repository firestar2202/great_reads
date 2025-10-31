import SwiftUI

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
