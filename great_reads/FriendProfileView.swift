//
//  FriendProfileView.swift
//  great_reads
//
//  Created by Justin Haddad on 10/28/25.
//


import SwiftUI

struct FriendProfileView: View {
    let friend: FirestoreUser
    @ObservedObject var userManager: UserManager
    @ObservedObject var bookManager: BookManager // Changed from @StateObject to @ObservedObject since it's passed in
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(friend.username.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                        )
                    
                    Text(friend.username)
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("\(bookManager.books.count) books")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
                // Books list
                if bookManager.books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No books yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bookManager.books) { book in
                                FriendBookCard(book: book)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
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

// MARK: - Friend Book Card (without delete button)
struct FriendBookCard: View {
    let book: FirestoreBook
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
                            .fill(book.primaryColor.opacity(0.3))
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
                            .fill(book.primaryColor.opacity(0.7))
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
                    .fill(book.primaryColor.opacity(0.7))
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            FriendBookDetailSheet(book: book)
        }
    }
}

// MARK: - Friend Book Detail Sheet
struct FriendBookDetailSheet: View {
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
                            Text("Their Review")
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
