//
//  great_readsApp.swift
//  great_reads
//
//  Created by Justin Haddad on 10/27/25.
//

import SwiftUI
import SwiftData

@main
struct great_readsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Book.self])
        }
    }
}
