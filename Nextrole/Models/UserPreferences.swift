//
//  UserPreferences.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var defaultLocation: String?
    var defaultRemotePreference: Bool
    var autoSaveSearches: Bool
    var notificationsEnabled: Bool

    // Scraping preferences
    var scrapingAggressiveness: ScrapingLevel
    var requestDelaySeconds: Double
    var maxResultsPerBoard: Int

    // Developer-specific defaults
    var defaultTechStack: [String] = []
    var preferredCompanyTypes: [String] = []
    var showSalaryEstimates: Bool

    init(
        defaultLocation: String? = nil,
        defaultRemotePreference: Bool = true,
        autoSaveSearches: Bool = true,
        notificationsEnabled: Bool = false,
        scrapingAggressiveness: ScrapingLevel = .normal,
        requestDelaySeconds: Double = 5.0,
        maxResultsPerBoard: Int = 100,
        defaultTechStack: [String] = [],
        preferredCompanyTypes: [String] = [],
        showSalaryEstimates: Bool = true
    ) {
        self.id = UUID()
        self.defaultLocation = defaultLocation
        self.defaultRemotePreference = defaultRemotePreference
        self.autoSaveSearches = autoSaveSearches
        self.notificationsEnabled = notificationsEnabled
        self.scrapingAggressiveness = scrapingAggressiveness
        self.requestDelaySeconds = requestDelaySeconds
        self.maxResultsPerBoard = maxResultsPerBoard
        self.defaultTechStack = defaultTechStack
        self.preferredCompanyTypes = preferredCompanyTypes
        self.showSalaryEstimates = showSalaryEstimates
    }
}

// MARK: - Scraping Level Enum
enum ScrapingLevel: String, Codable {
    case conservative // Slow, very respectful (10-15s delays)
    case normal       // Balanced (5-8s delays)
    case aggressive   // Fast but riskier (2-5s delays)

    var delayRange: ClosedRange<Double> {
        switch self {
        case .conservative:
            return 10.0...15.0
        case .normal:
            return 5.0...8.0
        case .aggressive:
            return 2.0...5.0
        }
    }

    var description: String {
        switch self {
        case .conservative:
            return "Conservative (Slowest, Most Respectful)"
        case .normal:
            return "Normal (Balanced)"
        case .aggressive:
            return "Aggressive (Fastest, Higher Risk)"
        }
    }
}
