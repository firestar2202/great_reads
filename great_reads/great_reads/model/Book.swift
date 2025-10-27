//
//  book.swift
//  great_reads
//
//  Created by Simon Chervenak on 10/27/25.
//

import SwiftData
import SwiftUI

@Model
final class Book {
    var author: String
    var title: String
    var tags: [Tag]

    init(title: String, author: String, tags: [Tag]) {
        self.author = author
        self.title = title
        self.tags = tags
    }
}
