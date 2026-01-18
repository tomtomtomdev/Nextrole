//
//  SearchViewModel.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // Services
    private var resumeService: ResumeService?
    private var searchService: JobSearchService?

    // Resume state
    @Published var currentResume: ResumeProfile?

    // Search filters
    @Published var keywordsText: String = ""
    @Published var locationText: String = ""
    @Published var remoteOnly: Bool = false
    @Published var offersRelocation: Bool = false
    @Published var requiresVisaSponsorship: Bool = false
    @Published var postedWithinDays: Int? = nil
    @Published var minimumMatchScore: Double = 0.75

    // Search state
    @Published var isSearching: Bool = false
    @Published var searchProgressValue: Double = 0.0
    @Published var searchProgressMessage: String = ""
    @Published var jobPostings: [JobPosting] = []
    @Published var selectedJobID: UUID?
    @Published var errorMessage: String?
    @Published var searchLogs: [String] = []

    // Computed properties
    var canSearch: Bool {
        currentResume != nil && !isSearching
    }

    var keywords: [String] {
        keywordsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Initialization
    func configure(with context: ModelContext) {
        self.resumeService = ResumeService(modelContext: context)
        self.searchService = JobSearchService(modelContext: context)
    }

    // MARK: - Resume Management
    func uploadResume(from url: URL) async {
        guard let service = resumeService else {
            errorMessage = "Service not initialized. Please restart the app."
            return
        }

        do {
            errorMessage = nil
            let resume = try await service.importResume(from: url)
            self.currentResume = resume
        } catch let error as NSError {
            // Provide user-friendly error messages
            if error.domain == NSCocoaErrorDomain {
                switch error.code {
                case NSFileReadNoPermissionError:
                    errorMessage = "Permission denied. Please select the file again and grant access."
                case NSFileNoSuchFileError:
                    errorMessage = "File not found. Please select a valid PDF file."
                case NSFileReadCorruptFileError:
                    errorMessage = "The PDF file is corrupted or invalid."
                default:
                    errorMessage = "Failed to read file: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to parse resume: \(error.localizedDescription)"
            }
        }
    }

    func removeResume() {
        guard let resume = currentResume, let service = resumeService else { return }

        do {
            try service.deleteResume(resume)
            currentResume = nil
            jobPostings = []
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete resume: \(error.localizedDescription)"
        }
    }

    // MARK: - Search Management
    func executeSearch() async {
        guard let resume = currentResume, let service = searchService else {
            errorMessage = "Please upload a resume first"
            return
        }

        isSearching = true
        errorMessage = nil
        jobPostings = []
        searchProgressValue = 0.0
        searchProgressMessage = "Preparing search..."
        searchLogs = []
        addLog("Starting job search...")

        let filters = SearchFilters(
            keywords: keywords,
            location: locationText.isEmpty ? nil : locationText,
            postedWithinDays: postedWithinDays,
            requiresRelocation: offersRelocation,
            remoteOnly: remoteOnly,
            visaSponsorshipRequired: requiresVisaSponsorship,
            minimumMatchScore: minimumMatchScore
        )

        do {
            // Update progress during search
            searchProgressMessage = "Analyzing resume..."
            searchProgressValue = 0.1
            addLog("Analyzing resume with \(resume.skills.count) skills")
            addLog("Keywords: \(keywords.joined(separator: ", "))")
            addLog("Location: \(locationText.isEmpty ? "Any" : locationText)")

            let results = try await service.searchJobs(
                resume: resume,
                filters: filters,
                progressHandler: { progress in
                    Task { @MainActor in
                        self.searchProgressValue = progress.value
                        self.searchProgressMessage = progress.message
                        self.addLog(progress.message)
                    }
                }
            )

            addLog("Search completed: \(results.count) jobs found")
            jobPostings = results
            searchProgressMessage = "Complete!"
            searchProgressValue = 1.0

        } catch {
            let errorMsg = "Search failed: \(error.localizedDescription)"
            errorMessage = errorMsg
            addLog("ERROR: \(errorMsg)")
        }

        isSearching = false
        addLog("Search finished")
    }

    func cancelSearch() {
        searchService?.cancelSearch()
        isSearching = false
        searchProgressMessage = "Cancelled"
    }

    func resetFilters() {
        keywordsText = ""
        locationText = ""
        remoteOnly = false
        offersRelocation = false
        requiresVisaSponsorship = false
        postedWithinDays = nil
        minimumMatchScore = 0.75
    }

    // MARK: - Logging
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        searchLogs.append("[\(timestamp)] \(message)")
    }
}

// MARK: - Search Filters
struct SearchFilters {
    var keywords: [String]
    var location: String?
    var postedWithinDays: Int?
    var requiresRelocation: Bool?
    var remoteOnly: Bool?
    var visaSponsorshipRequired: Bool?
    var minimumMatchScore: Double
}

// MARK: - Search Progress
struct SearchProgress {
    var value: Double
    var message: String
}
