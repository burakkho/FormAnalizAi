//
//  StorageService.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import Foundation
import Observation

// MARK: - Storage Service
@Observable
@MainActor
class StorageService {
    // State (only UI state on main thread)
    var error: AppError?

    // File Manager
    private let fileManager = FileManager.default

    // MARK: - Directory URLs
    /// Returns documents directory, falls back to temporary directory if unavailable
    private func getDocumentsDirectory() throws -> URL {
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Configuration.log("⚠️ Documents directory unavailable, using temp directory",
                            category: .storage,
                            level: .error)
            // Fallback to temporary directory
            return fileManager.temporaryDirectory
        }
        return directory
    }

    /// Legacy computed property - use getDocumentsDirectory() for better error handling
    private var documentsDirectory: URL {
        (try? getDocumentsDirectory()) ?? fileManager.temporaryDirectory
    }

    private var videosDirectory: URL {
        documentsDirectory.appendingPathComponent(Constants.Storage.videosDirectory, isDirectory: true)
    }

    private var thumbnailsDirectory: URL {
        documentsDirectory.appendingPathComponent(Constants.Storage.thumbnailsDirectory, isDirectory: true)
    }

    private var resultsDirectory: URL {
        documentsDirectory.appendingPathComponent(Constants.Storage.resultsDirectory, isDirectory: true)
    }

    // MARK: - Initialization
    init() {
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        let directories = [videosDirectory, thumbnailsDirectory, resultsDirectory]

        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                    Configuration.log("Created directory: \(directory.lastPathComponent)", category: .storage)
                } catch {
                    Configuration.log("Failed to create directory: \(error)", category: .storage)
                }
            }
        }
    }

    // MARK: - Save Video
    func saveVideo(_ data: Data, id: UUID) async throws -> URL {
        let fileName = "\(id.uuidString).mp4"
        let fileURL = videosDirectory.appendingPathComponent(fileName)

        do {
            try await writeData(data, to: fileURL)
            Configuration.log("Video saved: \(fileName)", category: .storage, level: .info)
            return fileURL
        } catch {
            Configuration.log("Failed to save video: \(error)", category: .storage, level: .error)
            self.error = .saveFailed
            throw AppError.saveFailed
        }
    }

    // MARK: - Save Thumbnail
    func saveThumbnail(_ data: Data, id: UUID) async throws -> URL {
        let fileName = "\(id.uuidString).jpg"
        let fileURL = thumbnailsDirectory.appendingPathComponent(fileName)

        do {
            try await writeData(data, to: fileURL)
            Configuration.log("Thumbnail saved: \(fileName)", category: .storage, level: .info)
            return fileURL
        } catch {
            Configuration.log("Failed to save thumbnail: \(error)", category: .storage, level: .error)
            self.error = .saveFailed
            throw AppError.saveFailed
        }
    }

    // MARK: - Save Analysis Session
    func saveSession(_ session: AnalysisSession) async throws {
        let fileName = "\(session.id.uuidString).json"
        let fileURL = resultsDirectory.appendingPathComponent(fileName)

        do {
            let data = try await Task.detached(priority: .utility) { () throws -> Data in
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                return try encoder.encode(session)
            }.value

            try await writeData(data, to: fileURL)
            Configuration.log("Session saved: \(fileName)", category: .storage, level: .info)
        } catch {
            Configuration.log("Failed to save session: \(error)", category: .storage, level: .error)
            self.error = .saveFailed
            throw AppError.saveFailed
        }
    }

    // MARK: - Load All Sessions
    func loadAllSessions() async throws -> [AnalysisSession] {
        do {
            let directory = resultsDirectory
            let sessions = try await Task.detached(priority: .utility) { () throws -> [AnalysisSession] in
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: .skipsHiddenFiles
                )

                let decoder = JSONDecoder()
                var loadedSessions: [AnalysisSession] = []

                for fileURL in fileURLs where fileURL.pathExtension == "json" {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let session = try decoder.decode(AnalysisSession.self, from: data)
                        loadedSessions.append(session)
                    } catch {
                        Configuration.log("Failed to load session at \(fileURL.lastPathComponent): \(error)", category: .storage)
                    }
                }

                loadedSessions.sort { $0.createdAt > $1.createdAt }
                return loadedSessions
            }.value

            Configuration.log("Loaded \(sessions.count) sessions", category: .storage)
            return sessions

        } catch {
            Configuration.log("Failed to load sessions: \(error)", category: .storage)
            await MainActor.run {
                self.error = .loadFailed
            }
            throw AppError.loadFailed
        }
    }

    // MARK: - Load Session by ID
    func loadSession(id: UUID) async throws -> AnalysisSession {
        let fileName = "\(id.uuidString).json"
        let fileURL = resultsDirectory.appendingPathComponent(fileName)

        do {
            let session = try await Task.detached(priority: .utility) { () throws -> AnalysisSession in
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                return try decoder.decode(AnalysisSession.self, from: data)
            }.value

            return session
        } catch {
            Configuration.log("Failed to load session: \(error)", category: .storage)
            await MainActor.run {
                self.error = .loadFailed
            }
            throw AppError.loadFailed
        }
    }

    // MARK: - Delete Session
    func deleteSession(_ session: AnalysisSession) throws {
        var deletionErrors: [String] = []

        // Delete session JSON
        let sessionFile = resultsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        do {
            try fileManager.removeItem(at: sessionFile)
        } catch {
            let errorMsg = "Failed to delete session file: \(error.localizedDescription)"
            Configuration.log(errorMsg, category: .storage, level: .error)
            deletionErrors.append(errorMsg)
        }

        // Delete video if exists
        if let videoPath = session.analysisResult.videoPath {
            let videoURL = URL(fileURLWithPath: videoPath)
            if fileManager.fileExists(atPath: videoURL.path) {
                do {
                    try fileManager.removeItem(at: videoURL)
                } catch {
                    let errorMsg = "Failed to delete video: \(error.localizedDescription)"
                    Configuration.log(errorMsg, category: .storage, level: .error)
                    deletionErrors.append(errorMsg)
                }
            }
        }

        // Delete thumbnail if exists
        if let thumbnailPath = session.analysisResult.videoThumbnailPath {
            let thumbURL = URL(fileURLWithPath: thumbnailPath)
            if fileManager.fileExists(atPath: thumbURL.path) {
                do {
                    try fileManager.removeItem(at: thumbURL)
                } catch {
                    let errorMsg = "Failed to delete thumbnail: \(error.localizedDescription)"
                    Configuration.log(errorMsg, category: .storage, level: .error)
                    deletionErrors.append(errorMsg)
                }
            }
        }

        if deletionErrors.isEmpty {
            Configuration.log("Session deleted successfully: \(session.id)", category: .storage)
        } else {
            Configuration.log("Session partially deleted with \(deletionErrors.count) errors",
                            category: .storage,
                            level: .error)
            // Don't throw - partial deletion is acceptable
        }
    }

    // MARK: - Get File URL
    func getVideoURL(for session: AnalysisSession) -> URL? {
        guard let path = session.analysisResult.videoPath else { return nil }
        let url = URL(fileURLWithPath: path)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func getThumbnailURL(for session: AnalysisSession) -> URL? {
        guard let path = session.analysisResult.videoThumbnailPath else { return nil }
        let url = URL(fileURLWithPath: path)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Helpers
    private func writeData(_ data: Data, to fileURL: URL) async throws {
        try await Task.detached(priority: .utility) {
            try data.write(to: fileURL, options: .atomic)
        }.value
    }

    // MARK: - Clear Cache
    func clearVideoCache() throws {
        var errors: [Error] = []

        // Delete videos directory
        do {
            try fileManager.removeItem(at: videosDirectory)
        } catch CocoaError.fileNoSuchFile {
            // Directory doesn't exist - that's OK
        } catch {
            Configuration.log("Failed to delete videos directory: \(error)",
                            category: .storage,
                            level: .error)
            errors.append(error)
        }

        // Delete thumbnails directory
        do {
            try fileManager.removeItem(at: thumbnailsDirectory)
        } catch CocoaError.fileNoSuchFile {
            // Directory doesn't exist - that's OK
        } catch {
            Configuration.log("Failed to delete thumbnails directory: \(error)",
                            category: .storage,
                            level: .error)
            errors.append(error)
        }

        // Recreate directories
        createDirectoriesIfNeeded()

        if errors.isEmpty {
            Configuration.log("Video cache cleared successfully", category: .storage, level: .info)
        } else {
            Configuration.log("Video cache partially cleared with \(errors.count) errors",
                            category: .storage,
                            level: .error)
            throw AppError.deleteFailed
        }
    }

    // MARK: - Delete All Data
    func deleteAllData() throws {
        var errors: [Error] = []

        // Delete all directories
        let directories = [videosDirectory, thumbnailsDirectory, resultsDirectory]
        for directory in directories {
            do {
                try fileManager.removeItem(at: directory)
            } catch CocoaError.fileNoSuchFile {
                // Directory doesn't exist - that's OK
            } catch {
                Configuration.log("Failed to delete directory \(directory.lastPathComponent): \(error)",
                                category: .storage,
                                level: .error)
                errors.append(error)
            }
        }

        // Recreate directories
        createDirectoriesIfNeeded()

        if errors.isEmpty {
            Configuration.log("All data deleted successfully", category: .storage, level: .info)
        } else {
            Configuration.log("Data partially deleted with \(errors.count) errors",
                            category: .storage,
                            level: .error)
            throw AppError.deleteFailed
        }
    }

    // MARK: - Get Cache Size
    func getCacheSize() -> String {
        var totalSize: Int64 = 0

        let directories = [videosDirectory, thumbnailsDirectory]

        for directory in directories {
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }

        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
