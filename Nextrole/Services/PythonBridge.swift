//
//  PythonBridge.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import Foundation

/// Bridge for communicating with embedded Python runtime
class PythonBridge {
    static let shared = PythonBridge()

    private let pythonExecutable: String
    private let scriptsPath: String
    private var currentProcess: Process?

    private init() {
        #if DEBUG
        // Development mode: Use source Python files directly
        let projectPath = "/Users/tomtomtom/Documents/Nextrole"
        self.pythonExecutable = "/usr/bin/python3"
        self.scriptsPath = "\(projectPath)/Nextrole/Python"
        #else
        // Production mode: Use embedded Python in app bundle
        if let bundlePath = Bundle.main.resourcePath {
            self.pythonExecutable = "\(bundlePath)/Python/bin/python3"
            self.scriptsPath = "\(bundlePath)/Python"
        } else {
            // Fallback to system Python
            self.pythonExecutable = "/usr/bin/python3"
            self.scriptsPath = FileManager.default.currentDirectoryPath + "/Nextrole/Python"
        }
        #endif
    }

    // MARK: - Resume Parsing
    struct ResumeData: Codable {
        let text: String
        let skills: [String]
        let keywords: [String]
        let experience: [ExperienceItem]
        let location: String?
        let yearsExperience: Int?
    }

    struct ExperienceItem: Codable {
        let title: String
        let company: String
        let duration: String
    }

    func parseResume(at url: URL) async throws -> ResumeData {
        let scriptPath = "\(scriptsPath)/resume_parser.py"

        let input = [
            "action": "parse",
            "pdf_path": url.path
        ]

        let output: ResumeData = try await executePythonScript(
            scriptPath: scriptPath,
            input: input
        )

        return output
    }

    // MARK: - Job Scraping
    struct ScraperInput: Codable {
        let action: String
        let resumeData: ResumeDataInput
        let filters: FiltersInput
    }

    struct ResumeDataInput: Codable {
        let skills: [String]
        let keywords: [String]
        let location: String?
    }

    struct FiltersInput: Codable {
        let keywords: [String]
        let location: String?
        let remoteOnly: Bool?
        let postedWithinDays: Int?
        let techStack: [String]
        let visaSponsorship: Bool?
        let companyTypes: [String]
        let scrapingLevel: String
        let maxResults: Int
    }

    struct MatchBreakdown: Codable {
        let totalScore: Double
        let skillsScore: Double
        let skillsWeight: Double
        let keywordsScore: Double
        let keywordsWeight: Double
        let experienceScore: Double
        let experienceWeight: Double
        let locationScore: Double
        let locationWeight: Double
        let titleScore: Double
        let titleWeight: Double
    }

    struct JobResult: Codable {
        let title: String
        let company: String
        let location: String
        let description: String
        let url: String
        let source: String
        let postedDate: String
        let isRemote: Bool
        let offersRelocation: Bool
        let matchScore: Double
        let matchBreakdown: MatchBreakdown?
        let techStack: [String]?
        let salaryRange: String?
        let visaSponsorship: Bool?
        let companySize: String?
    }

    struct ScraperOutput: Codable {
        let jobs: [JobResult]
        let errors: [String]
    }

    func searchJobs(
        resumeData: ResumeDataInput,
        filters: FiltersInput,
        progressHandler: @escaping (String, Double) -> Void
    ) async throws -> ScraperOutput {
        let scriptPath = "\(scriptsPath)/job_search.py"

        let input = ScraperInput(
            action: "search",
            resumeData: resumeData,
            filters: filters
        )

        // Start the process with progress monitoring
        let output: ScraperOutput = try await executePythonScriptWithProgress(
            scriptPath: scriptPath,
            input: input,
            progressHandler: progressHandler
        )

        return output
    }

    func cancelCurrentOperation() {
        currentProcess?.terminate()
        currentProcess = nil
    }

    // MARK: - Python Execution
    private func executePythonScript<Input: Encodable, Output: Decodable>(
        scriptPath: String,
        input: Input
    ) async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    self.currentProcess = process

                    process.executableURL = URL(fileURLWithPath: self.pythonExecutable)
                    process.arguments = [scriptPath]

                    // Set up pipes for communication
                    let inputPipe = Pipe()
                    let outputPipe = Pipe()
                    let errorPipe = Pipe()

                    process.standardInput = inputPipe
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    // Set Python path environment
                    var environment = ProcessInfo.processInfo.environment
                    environment["PYTHONPATH"] = self.scriptsPath
                    process.environment = environment

                    // Start process
                    try process.run()

                    // Write input as JSON
                    let encoder = JSONEncoder()
                    let inputData = try encoder.encode(input)
                    inputPipe.fileHandleForWriting.write(inputData)
                    try inputPipe.fileHandleForWriting.close()

                    // Read output
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    process.waitUntilExit()

                    if process.terminationStatus != 0 {
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        throw PythonBridgeError.scriptFailed(errorMessage)
                    }

                    // Decode output
                    let decoder = JSONDecoder()
                    let output = try decoder.decode(Output.self, from: outputData)

                    continuation.resume(returning: output)
                    self.currentProcess = nil

                } catch {
                    continuation.resume(throwing: error)
                    self.currentProcess = nil
                }
            }
        }
    }

    private func executePythonScriptWithProgress<Input: Encodable, Output: Decodable>(
        scriptPath: String,
        input: Input,
        progressHandler: @escaping (String, Double) -> Void
    ) async throws -> Output {
        // Similar to executePythonScript but monitors stderr for progress updates
        // Progress format: "PROGRESS: <message> | <0.0-1.0>"
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let process = Process()
                    self.currentProcess = process

                    process.executableURL = URL(fileURLWithPath: self.pythonExecutable)
                    process.arguments = [scriptPath]

                    let inputPipe = Pipe()
                    let outputPipe = Pipe()
                    let errorPipe = Pipe()

                    process.standardInput = inputPipe
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    var environment = ProcessInfo.processInfo.environment
                    environment["PYTHONPATH"] = self.scriptsPath
                    process.environment = environment

                    // Monitor stderr for progress updates
                    errorPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        if let line = String(data: data, encoding: .utf8) {
                            self.parseProgressLine(line, handler: progressHandler)
                        }
                    }

                    try process.run()

                    let encoder = JSONEncoder()
                    let inputData = try encoder.encode(input)
                    inputPipe.fileHandleForWriting.write(inputData)
                    try inputPipe.fileHandleForWriting.close()

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

                    process.waitUntilExit()

                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    if process.terminationStatus != 0 {
                        throw PythonBridgeError.scriptFailed("Python script failed")
                    }

                    let decoder = JSONDecoder()
                    let output = try decoder.decode(Output.self, from: outputData)

                    continuation.resume(returning: output)
                    self.currentProcess = nil

                } catch {
                    continuation.resume(throwing: error)
                    self.currentProcess = nil
                }
            }
        }
    }

    private func parseProgressLine(_ line: String, handler: @escaping (String, Double) -> Void) {
        // Parse lines like "PROGRESS: Searching LinkedIn | 0.25"
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else { return }

        if trimmedLine.hasPrefix("PROGRESS:") {
            let components = trimmedLine.dropFirst(9).split(separator: "|")
            if components.count == 2 {
                let message = components[0].trimmingCharacters(in: .whitespaces)
                if let value = Double(components[1].trimmingCharacters(in: .whitespaces)) {
                    DispatchQueue.main.async {
                        handler(message, value)
                    }
                }
            }
        } else {
            // Send all other stderr output as log messages with progress 0.0
            DispatchQueue.main.async {
                handler(trimmedLine, 0.0)
            }
        }
    }
}

// MARK: - Errors
enum PythonBridgeError: LocalizedError {
    case scriptNotFound
    case scriptFailed(String)
    case encodingError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .scriptNotFound:
            return "Python script not found"
        case .scriptFailed(let message):
            return "Python script failed: \(message)"
        case .encodingError:
            return "Failed to encode input data"
        case .decodingError:
            return "Failed to decode output data"
        }
    }
}
