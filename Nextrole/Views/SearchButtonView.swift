//
//  SearchButtonView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI

struct SearchButtonView: View {
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Progress indicator
            if viewModel.isSearching {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.searchProgressValue) {
                        Text(viewModel.searchProgressMessage)
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)

                    Button("Cancel") {
                        viewModel.cancelSearch()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            } else {
                // Search button
                Button(action: {
                    Task {
                        await viewModel.executeSearch()
                    }
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Jobs")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSearch)

                // Result count
                if viewModel.jobPostings.count > 0 {
                    Text("\(viewModel.jobPostings.count) jobs found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VStack {
        SearchButtonView()
            .environmentObject(SearchViewModel())

        Divider()

        // Searching state preview
        SearchButtonView()
            .environmentObject({
                let vm = SearchViewModel()
                vm.isSearching = true
                vm.searchProgressMessage = "Searching LinkedIn..."
                vm.searchProgressValue = 0.4
                return vm
            }())
    }
    .padding()
    .frame(width: 350)
}
