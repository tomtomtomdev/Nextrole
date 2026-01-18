//
//  ContentView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationSplitView {
            // Sidebar: Resume + Filters
            SidebarView()
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
        } detail: {
            // Main content: Results list
            JobResultsView()
                .frame(minWidth: 600, idealWidth: 800)
        }
        .navigationTitle("Nextrole")
        .environmentObject(viewModel)
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Resume Upload Section
            ResumeUploadView()
                .padding()

            Divider()

            // Search Filters Section
            ScrollView {
                SearchFiltersView()
                    .padding()
            }

            Divider()

            // Search Button
            SearchButtonView()
                .padding()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ResumeProfile.self, JobPosting.self, SearchQuery.self, UserPreferences.self], inMemory: true)
}
