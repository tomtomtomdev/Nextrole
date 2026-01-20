//
//  JobPosting.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Model
final class JobPosting {
    var id: UUID
    var title: String
    var company: String
    var location: String
    var jobDescription: String
    var url: String
    var source: String // LinkedIn, Indeed, Greenhouse, Workday
    var postedDate: Date
    var isRemote: Bool
    var offersRelocation: Bool
    var matchScore: Double
    var scrapedDate: Date

    // Match score breakdown
    var skillsScore: Double = 0.0
    var keywordsScore: Double = 0.0
    var experienceScore: Double = 0.0
    var locationScore: Double = 0.0
    var titleScore: Double = 0.0

    // Developer-specific fields
    var techStack: [String] = []
    var salaryRange: String?
    var offersVisaSponsorship: Bool?
    var companySize: String? // Startup, Mid-size, Enterprise
    var engineeringBlogURL: String?

    // User tracking
    var isViewed: Bool = false
    var isSaved: Bool = false
    var isApplied: Bool = false
    var appliedDate: Date?
    var notes: String?

    // Relationship
    @Relationship var searchQuery: SearchQuery?

    init(
        title: String,
        company: String,
        location: String,
        jobDescription: String,
        url: String,
        source: String,
        postedDate: Date,
        isRemote: Bool = false,
        offersRelocation: Bool = false,
        matchScore: Double = 0.0,
        skillsScore: Double = 0.0,
        keywordsScore: Double = 0.0,
        experienceScore: Double = 0.0,
        locationScore: Double = 0.0,
        titleScore: Double = 0.0,
        techStack: [String] = [],
        salaryRange: String? = nil,
        offersVisaSponsorship: Bool? = nil,
        companySize: String? = nil,
        engineeringBlogURL: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.company = company
        self.location = location
        self.jobDescription = jobDescription
        self.url = url
        self.source = source
        self.postedDate = postedDate
        self.isRemote = isRemote
        self.offersRelocation = offersRelocation
        self.matchScore = matchScore
        self.skillsScore = skillsScore
        self.keywordsScore = keywordsScore
        self.experienceScore = experienceScore
        self.locationScore = locationScore
        self.titleScore = titleScore
        self.scrapedDate = Date()
        self.techStack = techStack
        self.salaryRange = salaryRange
        self.offersVisaSponsorship = offersVisaSponsorship
        self.companySize = companySize
        self.engineeringBlogURL = engineeringBlogURL
    }
}

// MARK: - Computed Properties
extension JobPosting {
    var matchScoreFormatted: String {
        String(format: "%.0f%%", matchScore * 100)
    }

    var postedDateRelative: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: postedDate, to: now)

        if let days = components.day {
            if days == 0 {
                if let hours = components.hour {
                    return hours <= 1 ? "1 hour ago" : "\(hours) hours ago"
                }
                return "Today"
            } else if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            } else {
                let months = days / 30
                return months == 1 ? "1 month ago" : "\(months) months ago"
            }
        }

        return "Unknown"
    }

    var isNew: Bool {
        let calendar = Calendar.current
        let now = Date()
        if let daysDiff = calendar.dateComponents([.day], from: postedDate, to: now).day {
            return daysDiff <= 1
        }
        return false
    }

    var techStackDisplay: String {
        techStack.isEmpty ? "Not specified" : techStack.joined(separator: ", ")
    }
}
