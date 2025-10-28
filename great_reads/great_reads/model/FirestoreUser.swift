//
//  FirestoreUser.swift
//  great_reads
//
//  Created by Justin Haddad on 10/28/25.
//


import Foundation
import FirebaseFirestore

struct FirestoreUser: Codable, Identifiable {
    @DocumentID var id: String? // This will be the Firebase Auth UID
    var username: String
    var email: String
    var createdAt: Date
    var friends: [String] // Array of friend user IDs
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case createdAt
        case friends
    }
}


