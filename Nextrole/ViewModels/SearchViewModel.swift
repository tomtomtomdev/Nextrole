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
    private var modelContext: ModelContext?

    // Resume state
    @Published var currentResume: ResumeProfile? {
        didSet {
            saveResumeState()
        }
    }

    // Search filters
    @Published var keywordsText: String = "" {
        didSet {
            saveKeywordsState()
        }
    }
    @Published var locationText: String = "" {
        didSet {
            saveLocationState()
        }
    }
    @Published var remoteOnly: Bool = false
    @Published var offersRelocation: Bool = false
    @Published var requiresVisaSponsorship: Bool = false
    @Published var postedWithinDays: Int? = nil

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
        self.modelContext = context
        self.resumeService = ResumeService(modelContext: context)
        self.searchService = JobSearchService(modelContext: context)
        loadSavedState()
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
            visaSponsorshipRequired: requiresVisaSponsorship
        )

        do {
            // Update progress during search
            searchProgressMessage = "Analyzing resume..."
            searchProgressValue = 0.1
            addLog("Analyzing resume with \(resume.skills.count) skills")
            addLog("Keywords: \(keywords.joined(separator: ", "))")
            addLog("Location: \(locationText.isEmpty ? "Any" : locationText)")

            let result = try await service.searchJobs(
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

            addLog("Search completed: \(result.jobs.count) jobs found")
            jobPostings = result.jobs
            saveLastSearchQueryID(result.queryID)
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
    }

    // MARK: - Logging
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        searchLogs.append("[\(timestamp)] \(message)")
    }

    // MARK: - State Persistence
    private func getOrCreatePreferences() -> UserPreferences? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        // Create new preferences if none exist
        let newPreferences = UserPreferences()
        context.insert(newPreferences)
        try? context.save()
        return newPreferences
    }

    private func loadSavedState() {
        guard let preferences = getOrCreatePreferences(),
              let service = resumeService else { return }

        // Restore keywords and location
        if !preferences.lastUsedKeywords.isEmpty {
            keywordsText = preferences.lastUsedKeywords
        }
        if !preferences.lastUsedLocation.isEmpty {
            locationText = preferences.lastUsedLocation
        }

        // Restore last used resume
        if let resumeID = preferences.lastUsedResumeID {
            let allResumes = service.fetchAllResumes()
            if let savedResume = allResumes.first(where: { $0.id == resumeID }) {
                currentResume = savedResume
                addLog("Restored last used resume: \(savedResume.fileName)")
            }
        }

        // Restore cached job postings
        loadCachedJobPostings()
    }

    private func saveResumeState() {
        guard let preferences = getOrCreatePreferences(),
              let context = modelContext else { return }

        preferences.lastUsedResumeID = currentResume?.id
        try? context.save()
    }

    private func saveKeywordsState() {
        guard let preferences = getOrCreatePreferences(),
              let context = modelContext else { return }

        preferences.lastUsedKeywords = keywordsText
        try? context.save()
    }

    private func saveLocationState() {
        guard let preferences = getOrCreatePreferences(),
              let context = modelContext else { return }

        preferences.lastUsedLocation = locationText
        try? context.save()
    }

    private func saveLastSearchQueryID(_ queryID: UUID) {
        guard let preferences = getOrCreatePreferences(),
              let context = modelContext else { return }

        preferences.lastSearchQueryID = queryID
        try? context.save()
        addLog("Saved search results to cache")
    }

    private func loadCachedJobPostings() {
        guard let preferences = getOrCreatePreferences(),
              let queryID = preferences.lastSearchQueryID,
              let service = searchService else { return }

        let cachedJobs = service.fetchJobPostings(forQueryID: queryID)
        if !cachedJobs.isEmpty {
            jobPostings = cachedJobs
            addLog("Restored \(cachedJobs.count) cached job results")
        }
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
}

// MARK: - Search Progress
struct SearchProgress {
    var value: Double
    var message: String
}
