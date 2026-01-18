//
//  SearchButtonView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI

struct SearchButtonView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @State private var showLogsPopover = false

    var body: some View {
        VStack(spacing: 12) {
            // Progress indicator
            if viewModel.isSearching {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ProgressView(value: viewModel.searchProgressValue) {
                            Text(viewModel.searchProgressMessage)
                                .font(.caption)
                        }
                        .progressViewStyle(.linear)

                        // Verbose logs button
                        Button(action: {
                            showLogsPopover.toggle()
                        }) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("View detailed logs")
                        .popover(isPresented: $showLogsPopover, arrowEdge: .trailing) {
                            VerboseLogsView(logs: viewModel.searchLogs)
                        }
                    }

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

// MARK: - Verbose Logs View
struct VerboseLogsView: View {
    let logs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text("Search Logs")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            if logs.isEmpty {
                Text("No logs yet...")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(logColor(for: log))
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        if !logs.isEmpty {
                            proxy.scrollTo(logs.count - 1, anchor: .bottom)
                        }
                    }
                    .onChange(of: logs.count) { _, _ in
                        if !logs.isEmpty {
                            proxy.scrollTo(logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    private func logColor(for log: String) -> Color {
        if log.contains("ERROR") || log.contains("failed") {
            return .red
        } else if log.contains("Complete") || log.contains("SUCCESS") {
            return .green
        } else if log.contains("Searching") || log.contains("PROGRESS") {
            return .blue
        } else {
            return .primary
        }
    }
}
