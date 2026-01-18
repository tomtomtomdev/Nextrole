//
//  ResumeProfile.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Model
final class ResumeProfile {
    var id: UUID
    var fileName: String
    var fileURL: URL?
    var uploadDate: Date
    var parsedText: String
    var skills: [String]
    var keywords: [String]
    var location: String?
    var yearsOfExperience: Int?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \SearchQuery.resume)
    var searches: [SearchQuery] = []

    init(
        fileName: String,
        fileURL: URL? = nil,
        parsedText: String = "",
        skills: [String] = [],
        keywords: [String] = [],
        location: String? = nil,
        yearsOfExperience: Int? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.fileURL = fileURL
        self.uploadDate = Date()
        self.parsedText = parsedText
        self.skills = skills
        self.keywords = keywords
        self.location = location
        self.yearsOfExperience = yearsOfExperience
    }
}

// MARK: - Computed Properties
extension ResumeProfile {
    var skillsDisplay: String {
        skills.prefix(10).joined(separator: ", ")
    }

    var totalSkillsCount: Int {
        skills.count
    }

    var hasValidData: Bool {
        !parsedText.isEmpty && !skills.isEmpty
    }
}
