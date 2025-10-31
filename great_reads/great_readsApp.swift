//
//  great_readsApp.swift
//  great_reads
//
//  Created by Justin Haddad on 10/27/25.
//

import SwiftUI
import FirebaseCore

@main
struct great_readsApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}
