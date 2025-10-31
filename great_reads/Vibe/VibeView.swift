//
//  VibeView.swift
//  great_reads
//
//  Created by Justin Haddad on 10/29/25.
//


import SwiftUI

struct VibeView: View {
    @ObservedObject var userManager: UserManager
    @StateObject private var vibeManager = VibeManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let vibe = userManager.currentUser?.currentVibe,
                       let generatedAt = userManager.currentUser?.vibeGeneratedAt {
                        // Display the vibe
                        VStack(spacing: 16) {
                            // Vibe text
                            Text(vibe)
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .italic()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.blue.opacity(0.1))
                                        .shadow(color: .black.opacity(0.05), radius: 10)
                                )
                            
                            // Timestamp
                            Text("Generated \(timeAgo(from: generatedAt))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Regenerate button
                        Button(action: {
                            regenerateVibe()
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Regenerate Vibe")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding()
                        .disabled(vibeManager.isGenerating)
                        
                        // Books used section
                        if !vibeManager.recentBooks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Based on your last \(vibeManager.recentBooks.count) books")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(vibeManager.recentBooks) { book in
                                    VibeBookRow(book: book)
                                }
                            }
                        }
                        
                    } else {
                        // No vibe yet - empty state
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(.blue.opacity(0.5))
                            
                            Text("Discover Your Vibe")
                                .font(.title2.bold())
                            
                            Text("Generate a poetic vibe based on your recent reading")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            if vibeManager.recentBooks.isEmpty {
                                Text("Add some books first to generate your vibe!")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.top, 8)
                            }
                            
                            Button(action: {
                                regenerateVibe()
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Generate My Vibe")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(vibeManager.recentBooks.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            .disabled(vibeManager.isGenerating || vibeManager.recentBooks.isEmpty)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    }
                    
                    // Loading indicator
                    if vibeManager.isGenerating {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Generating your vibe...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    
                    // Error message
                    if let error = vibeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Your Vibe")
            .onAppear {
                if let userId = userManager.currentUser?.id {
                    Task {
                        await vibeManager.fetchRecentBooks(userId: userId)
                    }
                }
            }
        }
    }
    
    private func regenerateVibe() {
        guard let userId = userManager.currentUser?.id else { return }
        
        Task {
            do {
                // Fetch fresh books
                await vibeManager.fetchRecentBooks(userId: userId)
                
                // Generate vibe
                try await vibeManager.generateAndSaveVibe(userId: userId)
                
                // Refresh user profile to get new vibe
                try await userManager.fetchUserProfile(userId: userId)
            } catch {
                print("Error generating vibe: \(error)")
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Small book row for vibe list
struct VibeBookRow: View {
    let book: FirestoreBook
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover image or placeholder
            if let coverURLString = book.coverImageURL,
               let coverURL = URL(string: coverURLString) {
                AsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(book.primaryColor.opacity(0.3))
                }
                .frame(width: 40, height: 60)
                .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(book.primaryColor.opacity(0.7))
                    .frame(width: 40, height: 60)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    VibeView(userManager: UserManager())
}
