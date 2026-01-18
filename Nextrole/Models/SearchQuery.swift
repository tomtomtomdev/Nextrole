//
//  SearchQuery.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Model
final class SearchQuery {
    var id: UUID
    var keywords: [String]
    var location: String?
    var postedWithinDays: Int?
    var requiresRelocation: Bool?
    var remoteOnly: Bool?
    var executedDate: Date

    // Developer-specific filters
    var techStackFilter: [String] = []
    var visaSponsorshipRequired: Bool?
    var companyTypeFilter: [String] = [] // Startup, Enterprise, etc.
    var minimumMatchScore: Double = 0.5

    // Relationships
    @Relationship var resume: ResumeProfile?
    @Relationship(deleteRule: .cascade) var jobPostings: [JobPosting] = []

    init(
        keywords: [String] = [],
        location: String? = nil,
        postedWithinDays: Int? = nil,
        requiresRelocation: Bool? = nil,
        remoteOnly: Bool? = nil,
        techStackFilter: [String] = [],
        visaSponsorshipRequired: Bool? = nil,
        companyTypeFilter: [String] = [],
        minimumMatchScore: Double = 0.5
    ) {
        self.id = UUID()
        self.keywords = keywords
        self.location = location
        self.postedWithinDays = postedWithinDays
        self.requiresRelocation = requiresRelocation
        self.remoteOnly = remoteOnly
        self.executedDate = Date()
        self.techStackFilter = techStackFilter
        self.visaSponsorshipRequired = visaSponsorshipRequired
        self.companyTypeFilter = companyTypeFilter
        self.minimumMatchScore = minimumMatchScore
    }
}

// MARK: - Computed Properties
extension SearchQuery {
    var resultCount: Int {
        jobPostings.count
    }

    var hasResults: Bool {
        !jobPostings.isEmpty
    }

    var executedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: executedDate)
    }

    var filterSummary: String {
        var parts: [String] = []

        if !keywords.isEmpty {
            parts.append("Keywords: \(keywords.joined(separator: ", "))")
        }

        if let location = location {
            parts.append("Location: \(location)")
        }

        if remoteOnly == true {
            parts.append("Remote only")
        }

        if let days = postedWithinDays {
            parts.append("Posted within \(days) days")
        }

        if !techStackFilter.isEmpty {
            parts.append("Tech: \(techStackFilter.joined(separator: ", "))")
        }

        return parts.isEmpty ? "No filters" : parts.joined(separator: " | ")
    }
}
