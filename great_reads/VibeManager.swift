//
//  VibeManager.swift
//  great_reads
//
//  Created by Justin Haddad on 10/29/25.
//


import Foundation
import FirebaseFirestore
import Combine

@MainActor
class VibeManager: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var recentBooks: [FirestoreBook] = []
    
    private let db = Firestore.firestore()
    private let claudeService = ClaudeService()
    private let maxBooks = 10 // Configurable: how many books to use for vibe
    
    // Fetch recent books for vibe generation
    func fetchRecentBooks(userId: String) async {
        do {
            let snapshot = try await db.collection("books")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: maxBooks)
                .getDocuments()
            
            recentBooks = snapshot.documents.compactMap { doc in
                try? doc.data(as: FirestoreBook.self)
            }
            // Only keep books that have descriptions
            recentBooks = recentBooks.filter { $0.bookDescription != nil && !$0.bookDescription!.isEmpty }
        } catch {
            print("Error fetching recent books: \(error)")
        }
    }
    
    // Generate vibe and save to user profile
    func generateAndSaveVibe(userId: String) async throws {
        guard !recentBooks.isEmpty else {
            throw NSError(domain: "VibeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No books with descriptions found. Add some books first!"])
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            // Generate vibe using Claude
            let vibe = try await claudeService.generateVibe(from: recentBooks)
            
            // Save to Firestore
            try await db.collection("users").document(userId).updateData([
                "currentVibe": vibe,
                "vibeGeneratedAt": Date()
            ])
            
            isGenerating = false
        } catch {
            isGenerating = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
