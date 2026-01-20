//
//  SearchFiltersView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI

struct SearchFiltersView: View {
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Filters")
                .font(.headline)

            Form {
                // Keywords
                Section("Keywords") {
                    TextField("e.g., Swift, iOS, SwiftUI", text: $viewModel.keywordsText)
                        .textFieldStyle(.roundedBorder)

                    Text("Comma-separated keywords")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Location
                Section("Location") {
                    TextField("e.g., San Francisco, CA or Remote", text: $viewModel.locationText)
                        .textFieldStyle(.roundedBorder)
                }

                // Remote & Relocation
                Section("Work Arrangement") {
                    Toggle("Remote Only", isOn: $viewModel.remoteOnly)

                    Toggle("Offers Relocation", isOn: $viewModel.offersRelocation)

                    Toggle("Visa Sponsorship", isOn: $viewModel.requiresVisaSponsorship)
                }

                // Posted Date
                Section("Posted Date") {
                    Picker("Posted within", selection: $viewModel.postedWithinDays) {
                        Text("Any time").tag(nil as Int?)
                        Text("Today").tag(1 as Int?)
                        Text("3 days").tag(3 as Int?)
                        Text("Week").tag(7 as Int?)
                        Text("Month").tag(30 as Int?)
                    }
                    .pickerStyle(.menu)
                }
            }
            .formStyle(.grouped)

            // Reset filters button
            Button("Reset Filters") {
                viewModel.resetFilters()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
        }
    }
}

#Preview {
    SearchFiltersView()
        .environmentObject(SearchViewModel())
        .frame(width: 350)
}
