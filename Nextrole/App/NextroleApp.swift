//
//  NextroleApp.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI
import SwiftData

@main
struct NextroleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ResumeProfile.self,
            JobPosting.self,
            SearchQuery.self,
            UserPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}
