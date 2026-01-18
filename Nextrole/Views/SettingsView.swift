//
//  SettingsView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    @State private var defaultLocation: String = ""
    @State private var defaultRemotePreference: Bool = true
    @State private var autoSaveSearches: Bool = true
    @State private var scrapingLevel: ScrapingLevel = .normal
    @State private var maxResultsPerBoard: Int = 100

    var body: some View {
        TabView {
            generalSettingsView
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            scrapingSettingsView
                .tabItem {
                    Label("Scraping", systemImage: "network")
                }

            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadPreferences()
        }
    }

    // MARK: - General Settings
    private var generalSettingsView: some View {
        Form {
            Section("Default Search Settings") {
                TextField("Default Location", text: $defaultLocation)
                    .textFieldStyle(.roundedBorder)

                Toggle("Prefer Remote Jobs", isOn: $defaultRemotePreference)

                Toggle("Auto-save Searches", isOn: $autoSaveSearches)
            }

            Section {
                Button("Save Preferences") {
                    savePreferences()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Scraping Settings
    private var scrapingSettingsView: some View {
        Form {
            Section("Scraping Behavior") {
                Picker("Aggressiveness Level", selection: $scrapingLevel) {
                    Text(ScrapingLevel.conservative.description).tag(ScrapingLevel.conservative)
                    Text(ScrapingLevel.normal.description).tag(ScrapingLevel.normal)
                    Text(ScrapingLevel.aggressive.description).tag(ScrapingLevel.aggressive)
                }

                Text("Conservative: 10-15s delays, most respectful\nNormal: 5-8s delays, balanced approach\nAggressive: 2-5s delays, faster but higher risk")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Results") {
                Stepper("Max Results per Board: \(maxResultsPerBoard)", value: $maxResultsPerBoard, in: 10...500, step: 10)
            }

            Section {
                Text("⚠️ Disclaimer")
                    .font(.headline)

                Text("This tool scrapes public job postings. Users are responsible for compliance with each website's Terms of Service. Use respectfully and at your own risk.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Save Preferences") {
                    savePreferences()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About
    private var aboutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Nextrole")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A macOS app for matching your resume with jobs across multiple platforms")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 350)

            Divider()
                .frame(width: 300)

            VStack(spacing: 8) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/yourusername/nextrole")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/yourusername/nextrole/issues")!)
                Link("View License (MIT)", destination: URL(string: "https://opensource.org/licenses/MIT")!)
            }
            .font(.subheadline)

            Spacer()

            Text("Made with ❤️ for developers")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Helper Methods
    private func loadPreferences() {
        if let pref = preferences.first {
            defaultLocation = pref.defaultLocation ?? ""
            defaultRemotePreference = pref.defaultRemotePreference
            autoSaveSearches = pref.autoSaveSearches
            scrapingLevel = pref.scrapingAggressiveness
            maxResultsPerBoard = pref.maxResultsPerBoard
        }
    }

    private func savePreferences() {
        if let existingPref = preferences.first {
            existingPref.defaultLocation = defaultLocation.isEmpty ? nil : defaultLocation
            existingPref.defaultRemotePreference = defaultRemotePreference
            existingPref.autoSaveSearches = autoSaveSearches
            existingPref.scrapingAggressiveness = scrapingLevel
            existingPref.maxResultsPerBoard = maxResultsPerBoard
        } else {
            let newPref = UserPreferences(
                defaultLocation: defaultLocation.isEmpty ? nil : defaultLocation,
                defaultRemotePreference: defaultRemotePreference,
                autoSaveSearches: autoSaveSearches,
                scrapingAggressiveness: scrapingLevel,
                maxResultsPerBoard: maxResultsPerBoard
            )
            modelContext.insert(newPref)
        }

        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserPreferences.self], inMemory: true)
}
