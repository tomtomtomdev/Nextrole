//
//  JobResultsView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI

struct JobResultsView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @State private var sortOrder = [KeyPathComparator(\JobPosting.matchScore, order: .reverse)]
    @State private var searchText = ""
    @State private var showingBreakdownFor: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.jobPostings.isEmpty && !viewModel.isSearching {
                emptyStateView
            } else {
                jobsTableView
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Jobs Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Upload your resume and start searching for matching jobs")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Jobs Table
    private var jobsTableView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter results...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))

            Divider()

            // Table
            Table(filteredJobs, selection: $viewModel.selectedJobID, sortOrder: $sortOrder) {
                TableColumn("Match", value: \.matchScore) { job in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(matchScoreColor(job.matchScore))
                            .frame(width: 8, height: 8)
                        Text(job.matchScoreFormatted)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)

                        Button {
                            if showingBreakdownFor == job.id {
                                showingBreakdownFor = nil
                            } else {
                                showingBreakdownFor = job.id
                            }
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: Binding(
                            get: { showingBreakdownFor == job.id },
                            set: { if !$0 { showingBreakdownFor = nil } }
                        )) {
                            MatchBreakdownView(job: job)
                        }
                    }
                }
                .width(min: 90, max: 120)

                TableColumn("Title", value: \.title) { job in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(job.title)
                                .fontWeight(.medium)
                            if job.isNew {
                                Text("NEW")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.green)
                                    .cornerRadius(3)
                            }
                        }
                        if !job.techStack.isEmpty {
                            Text(job.techStack.prefix(3).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .width(min: 200)

                TableColumn("Company", value: \.company) { job in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.company)
                        if let size = job.companySize {
                            Text(size)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .width(min: 150)

                TableColumn("Location", value: \.location) { job in
                    HStack(spacing: 4) {
                        if job.isRemote {
                            Image(systemName: "wifi")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Text(job.location)
                    }
                }
                .width(min: 120)

                TableColumn("Posted", value: \.postedDate) { job in
                    Text(job.postedDateRelative)
                        .font(.caption)
                }
                .width(min: 100, max: 120)

                TableColumn("Source", value: \.source) { job in
                    Text(job.source)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(sourceColor(job.source).opacity(0.2))
                        .foregroundColor(sourceColor(job.source))
                        .cornerRadius(4)
                }
                .width(min: 90, max: 110)
            }
            .onChange(of: sortOrder) { _, newOrder in
                viewModel.jobPostings.sort(using: newOrder)
            }
            .contextMenu(forSelectionType: UUID.self) { items in
                if items.count == 1 {
                    Button("Open in Browser") {
                        if let job = viewModel.jobPostings.first(where: { $0.id == items.first }) {
                            openURL(job.url)
                        }
                    }
                    Button("Copy Link") {
                        if let job = viewModel.jobPostings.first(where: { $0.id == items.first }) {
                            copyToClipboard(job.url)
                        }
                    }
                    Divider()
                    Button("Save for Later") {
                        // TODO: Implement save functionality
                    }
                }
            } primaryAction: { items in
                // Double-click to open detail view or browser
                if let job = viewModel.jobPostings.first(where: { $0.id == items.first }) {
                    openURL(job.url)
                }
            }
        }
    }

    // MARK: - Filtered Jobs
    private var filteredJobs: [JobPosting] {
        if searchText.isEmpty {
            return viewModel.jobPostings
        } else {
            return viewModel.jobPostings.filter { job in
                job.title.localizedCaseInsensitiveContains(searchText) ||
                job.company.localizedCaseInsensitiveContains(searchText) ||
                job.location.localizedCaseInsensitiveContains(searchText) ||
                job.techStack.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }

    // MARK: - Helper Methods
    private func matchScoreColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .gray
        }
    }

    private func sourceColor(_ source: String) -> Color {
        switch source.lowercased() {
        case "linkedin":
            return .blue
        case "indeed":
            return .orange
        case "greenhouse":
            return .green
        case "workday":
            return .purple
        default:
            return .gray
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    JobResultsView()
        .environmentObject({
            let vm = SearchViewModel()
            // Add some sample jobs
            vm.jobPostings = [
                JobPosting(
                    title: "Senior iOS Developer",
                    company: "Apple Inc.",
                    location: "Cupertino, CA",
                    jobDescription: "Build amazing iOS apps",
                    url: "https://apple.com/jobs/1",
                    source: "LinkedIn",
                    postedDate: Date().addingTimeInterval(-86400),
                    isRemote: false,
                    matchScore: 0.92,
                    skillsScore: 0.95,
                    keywordsScore: 0.90,
                    experienceScore: 0.85,
                    locationScore: 1.0,
                    titleScore: 1.0,
                    techStack: ["Swift", "SwiftUI", "UIKit"]
                ),
                JobPosting(
                    title: "iOS Engineer",
                    company: "Google",
                    location: "Remote",
                    jobDescription: "Work on iOS apps",
                    url: "https://google.com/jobs/1",
                    source: "Indeed",
                    postedDate: Date().addingTimeInterval(-172800),
                    isRemote: true,
                    matchScore: 0.85,
                    skillsScore: 0.80,
                    keywordsScore: 0.85,
                    experienceScore: 0.90,
                    locationScore: 1.0,
                    titleScore: 0.5,
                    techStack: ["Swift", "Objective-C"]
                )
            ]
            return vm
        }())
        .frame(minWidth: 800, minHeight: 600)
}

// MARK: - Match Breakdown Popover View
struct MatchBreakdownView: View {
    let job: JobPosting

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Score Breakdown")
                .font(.headline)
                .padding(.bottom, 4)

            // Overall score
            HStack {
                Text("Overall Match")
                    .fontWeight(.semibold)
                Spacer()
                Text(job.matchScoreFormatted)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(job.matchScore))
            }

            Divider()

            // Individual factors (aligned with comprehensive analysis)
            BreakdownRow(
                label: "Tech Skills",
                score: job.skillsScore,
                weight: 0.40,
                icon: "hammer"
            )

            BreakdownRow(
                label: "Architecture",
                score: job.keywordsScore,
                weight: 0.20,
                icon: "building.2"
            )

            BreakdownRow(
                label: "Collab",
                score: job.titleScore,
                weight: 0.15,
                icon: "person.2"
            )

            BreakdownRow(
                label: "Experience",
                score: job.experienceScore,
                weight: 0.15,
                icon: "briefcase"
            )

            BreakdownRow(
                label: "Location",
                score: job.locationScore,
                weight: 0.10,
                icon: "location"
            )

            Divider()

            // Legend
            Text("Based on skills, architecture, collaboration, experience & location")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 280)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
}

struct BreakdownRow: View {
    let label: String
    let score: Double
    let weight: Double
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundColor(.secondary)

            Text(label)
                .frame(width: 80, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(barColor)
                        .frame(width: geometry.size.width * score, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.0f%%", score * 100))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 35, alignment: .trailing)

            Text(String(format: "(%.0f%%)", weight * 100))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }

    private var barColor: Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else if score >= 0.4 { return .yellow }
        else { return .red }
    }
}
