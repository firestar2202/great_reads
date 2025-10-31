//
//  Tag.swift
//  great_reads
//
//  Created by Simon Chervenak on 10/27/25.
//

import SwiftData
import SwiftUI

enum Tag: String, Codable, CaseIterable {
    case fantasy
    case scifi
    case romance
    case ya
    case horror
    case nonfiction
    case history
    case mystery
    case thriller
    case cookbook
    case science
    case selfHelp
    case travel
    case photography
    case business
    case art
    case education
    case religion
    case literature
    case children
    case cooking
    case gardening
    case fashion
    case beauty
    case design
    
    var color: Color {
            switch self {
            case .fantasy:
                return .purple
            case .scifi:
                return .blue
            case .romance:
                return .pink
            case .ya:
                return .cyan
            case .horror:
                return Color(red: 0.4, green: 0.0, blue: 0.0) // Dark red
            case .nonfiction:
                return .gray
            case .history:
                return .brown
            case .mystery:
                return Color(red: 0.2, green: 0.1, blue: 0.3) // Dark purple
            case .thriller:
                return .red
            case .cookbook:
                return .orange
            case .science:
                return .green
            case .selfHelp:
                return .mint
            case .travel:
                return .teal
            case .photography:
                return Color(red: 0.5, green: 0.5, blue: 0.5) // Medium gray
            case .business:
                return .indigo
            case .art:
                return Color(red: 1.0, green: 0.4, blue: 0.8) // Bright pink
            case .education:
                return Color(red: 0.0, green: 0.4, blue: 0.8) // Bright blue
            case .religion:
                return Color(red: 0.6, green: 0.4, blue: 0.2) // Gold/tan
            case .literature:
                return Color(red: 0.3, green: 0.2, blue: 0.1) // Dark brown
            case .children:
                return .yellow
            case .cooking:
                return Color(red: 1.0, green: 0.5, blue: 0.0) // Bright orange
            case .gardening:
                return Color(red: 0.4, green: 0.7, blue: 0.3) // Light green
            case .fashion:
                return Color(red: 0.9, green: 0.2, blue: 0.5) // Hot pink
            case .beauty:
                return Color(red: 1.0, green: 0.7, blue: 0.8) // Light pink
            case .design:
                return Color(red: 0.5, green: 0.0, blue: 0.5) // Purple
            }
        }
}
