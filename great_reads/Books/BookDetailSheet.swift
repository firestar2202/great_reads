import SwiftUI

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
