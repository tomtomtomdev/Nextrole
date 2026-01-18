//
//  ResumeUploadView.swift
//  Nextrole
//
//  Created by Claude Code on 2026-01-18.
//

import SwiftUI
import UniformTypeIdentifiers

struct ResumeUploadView: View {
    @EnvironmentObject var viewModel: SearchViewModel
    @State private var isFileImporterPresented = false
    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resume")
                .font(.headline)

            if let resume = viewModel.currentResume {
                // Resume loaded state
                resumeLoadedView(resume: resume)
            } else {
                // Empty state - drag and drop or select
                resumeEmptyView
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    // MARK: - Resume Loaded View
    private func resumeLoadedView(resume: ResumeProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(resume.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("Uploaded \(resume.uploadDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    viewModel.removeResume()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove resume")
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            // Skills preview
            if !resume.skills.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected Skills (\(resume.totalSkillsCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(resume.skills.prefix(10), id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }

                            if resume.totalSkillsCount > 10 {
                                Text("+\(resume.totalSkillsCount - 10) more")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Resume Empty View
    private var resumeEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(isDragging ? .blue : .secondary)

            Text("Drop PDF or Click to Select")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Select Resume PDF") {
                isFileImporterPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isDragging ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [5])
                )
        )
        .onDrop(of: [.pdf], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - Helper Methods
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    await viewModel.uploadResume(from: url)
                }
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
            viewModel.errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { (item, error) in
            if let error = error {
                print("Error loading dropped file: \(error.localizedDescription)")
                return
            }

            if let url = item as? URL {
                Task {
                    await viewModel.uploadResume(from: url)
                }
            } else if let data = item as? Data {
                // Handle data if needed
                print("Received data: \(data.count) bytes")
            }
        }

        return true
    }
}

#Preview {
    ResumeUploadView()
        .environmentObject(SearchViewModel())
        .frame(width: 350)
        .padding()
}
