import SwiftUI

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
