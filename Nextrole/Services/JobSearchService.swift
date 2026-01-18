//
//  JobSearchService.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Observable
class JobSearchService {
    private let modelContext: ModelContext
    private let pythonBridge = PythonBridge.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Search Jobs
    func searchJobs(
        resume: ResumeProfile,
        filters: SearchFilters,
        progressHandler: @escaping (SearchProgress) -> Void
    ) async throws -> [JobPosting] {
        // 1. Prepare input for Python scrapers
        let resumeData = PythonBridge.ResumeDataInput(
            skills: resume.skills,
            keywords: resume.keywords,
            location: resume.location
        )

        // Load user preferences for scraping settings
        let preferences = try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first
        let scrapingLevel = preferences?.scrapingAggressiveness ?? .normal
        let maxResults = preferences?.maxResultsPerBoard ?? 100

        let pythonFilters = PythonBridge.FiltersInput(
            keywords: filters.keywords,
            location: filters.location,
            remoteOnly: filters.remoteOnly,
            postedWithinDays: filters.postedWithinDays,
            techStack: filters.techStackFilter,
            visaSponsorship: filters.visaSponsorshipRequired,
            companyTypes: filters.companyTypeFilter,
            scrapingLevel: scrapingLevel.rawValue,
            maxResults: maxResults
        )

        // 2. Call Python scrapers with progress updates
        progressHandler(SearchProgress(value: 0.1, message: "Starting scrapers..."))

        let scraperOutput = try await pythonBridge.searchJobs(
            resumeData: resumeData,
            filters: pythonFilters,
            progressHandler: { message, value in
                progressHandler(SearchProgress(value: value, message: message))
            }
        )

        progressHandler(SearchProgress(value: 0.9, message: "Processing results..."))

        // 3. Create JobPosting models
        var jobPostings: [JobPosting] = []

        for jobResult in scraperOutput.jobs {
            // Parse posted date
            let dateFormatter = ISO8601DateFormatter()
            let postedDate = dateFormatter.date(from: jobResult.postedDate) ?? Date()

            // Filter by minimum match score
            guard jobResult.matchScore >= filters.minimumMatchScore else {
                continue
            }

            let posting = JobPosting(
                title: jobResult.title,
                company: jobResult.company,
                location: jobResult.location,
                jobDescription: jobResult.description,
                url: jobResult.url,
                source: jobResult.source,
                postedDate: postedDate,
                isRemote: jobResult.isRemote,
                offersRelocation: jobResult.offersRelocation,
                matchScore: jobResult.matchScore,
                techStack: jobResult.techStack ?? [],
                salaryRange: jobResult.salaryRange,
                offersVisaSponsorship: jobResult.visaSponsorship,
                companySize: jobResult.companySize
            )

            jobPostings.append(posting)
        }

        // 4. Create SearchQuery and save to database
        let searchQuery = SearchQuery(
            keywords: filters.keywords,
            location: filters.location,
            postedWithinDays: filters.postedWithinDays,
            requiresRelocation: filters.requiresRelocation,
            remoteOnly: filters.remoteOnly,
            techStackFilter: filters.techStackFilter,
            visaSponsorshipRequired: filters.visaSponsorshipRequired,
            companyTypeFilter: filters.companyTypeFilter,
            minimumMatchScore: filters.minimumMatchScore
        )

        searchQuery.resume = resume
        modelContext.insert(searchQuery)

        // Link job postings to search query
        for posting in jobPostings {
            posting.searchQuery = searchQuery
            modelContext.insert(posting)
        }

        try modelContext.save()

        progressHandler(SearchProgress(value: 1.0, message: "Complete!"))

        // 5. Return sorted results
        return jobPostings.sorted { $0.matchScore > $1.matchScore }
    }

    // MARK: - Cancel Search
    func cancelSearch() {
        pythonBridge.cancelCurrentOperation()
    }

    // MARK: - Fetch Saved Searches
    func fetchSearchHistory() -> [SearchQuery] {
        let descriptor = FetchDescriptor<SearchQuery>(
            sortBy: [SortDescriptor(\.executedDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Delete Search
    func deleteSearch(_ query: SearchQuery) throws {
        modelContext.delete(query)
        try modelContext.save()
    }
}
