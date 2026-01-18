//
//  ResumeService.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Observable
class ResumeService {
    private let modelContext: ModelContext
    private let pythonBridge = PythonBridge.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Import Resume
    func importResume(from url: URL) async throws -> ResumeProfile {
        // Request access to security-scoped resource
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // 1. Copy PDF to app's document directory
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let destinationURL = documentsURL
            .appendingPathComponent("Resumes", isDirectory: true)
            .appendingPathComponent(url.lastPathComponent)

        try? FileManager.default.createDirectory(
            at: documentsURL.appendingPathComponent("Resumes", isDirectory: true),
            withIntermediateDirectories: true
        )

        // Copy file if it's not already in our directory
        if url != destinationURL {
            try? FileManager.default.removeItem(at: destinationURL) // Remove if exists
            try FileManager.default.copyItem(at: url, to: destinationURL)
        }

        // 2. Parse resume with Python
        let parsedData = try await pythonBridge.parseResume(at: destinationURL)

        // 3. Create ResumeProfile model
        let profile = ResumeProfile(
            fileName: url.lastPathComponent,
            fileURL: destinationURL,
            parsedText: parsedData.text,
            skills: parsedData.skills,
            keywords: parsedData.keywords,
            location: parsedData.location,
            yearsOfExperience: parsedData.yearsExperience
        )

        // 4. Save to SwiftData
        modelContext.insert(profile)
        try modelContext.save()

        return profile
    }

    // MARK: - Delete Resume
    func deleteResume(_ profile: ResumeProfile) throws {
        // Delete file from disk
        if let fileURL = profile.fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Delete from database
        modelContext.delete(profile)
        try modelContext.save()
    }

    // MARK: - List All Resumes
    func fetchAllResumes() -> [ResumeProfile] {
        let descriptor = FetchDescriptor<ResumeProfile>(
            sortBy: [SortDescriptor(\.uploadDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
