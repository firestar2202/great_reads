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
    @StateObject private var bookManager = BookManager()
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
                                FirestoreBookCard(book: book, onDelete: {})
                                    .disabled(true) // Can't delete friend's books
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
            .onAppear {
                if let friendId = friend.id {
                    bookManager.fetchUserBooks(userId: friendId)
                }
            }
        }
    }
}
