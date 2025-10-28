//
//  FirestoreBook.swift
//  great_reads
//
//  Created by Justin Haddad on 10/28/25.
//


import Foundation
import FirebaseFirestore
import SwiftUI

struct FirestoreBook: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var tags: [String] // Store as strings for Firestore
    var userId: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case tags
        case userId
        case createdAt
    }
    
    // Helper to convert tags to Tag enums
    var tagEnums: [Tag] {
        tags.compactMap { Tag(rawValue: $0) }
    }
    
    // Helper to get primary color (from first tag)
    var primaryColor: Color {
        tagEnums.first?.color ?? .blue
    }
}
