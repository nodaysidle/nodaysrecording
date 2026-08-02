import AppKit
import Foundation

@MainActor
final class LocalStore {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    let rootURL: URL
    let recordingsURL: URL
    private let recordingsIndexURL: URL
    private let presetsIndexURL: URL

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        rootURL = base.appendingPathComponent("NoDays Record", isDirectory: true)
        recordingsURL = rootURL.appendingPathComponent("Recordings", isDirectory: true)
        recordingsIndexURL = rootURL.appendingPathComponent("recordings.json")
        presetsIndexURL = rootURL.appendingPathComponent("presets.json")

        try? fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
    }

    func loadRecordings() -> [Recording] {
        guard let data = try? Data(contentsOf: recordingsIndexURL),
              let recordings = try? decoder.decode([Recording].self, from: data) else {
            return []
        }
        return recordings.filter(\.existsOnDisk).sorted { $0.createdAt > $1.createdAt }
    }

    func saveRecordings(_ recordings: [Recording]) {
        guard let data = try? encoder.encode(recordings) else { return }
        try? data.write(to: recordingsIndexURL, options: .atomic)
    }

    func loadPresets() -> [Preset] {
        guard let data = try? Data(contentsOf: presetsIndexURL),
              let presets = try? decoder.decode([Preset].self, from: data) else {
            return []
        }
        return presets.sorted { $0.createdAt < $1.createdAt }
    }

    func savePresets(_ presets: [Preset]) {
        guard let data = try? encoder.encode(presets) else { return }
        try? data.write(to: presetsIndexURL, options: .atomic)
    }

    func newRecordingURL(for id: UUID) -> URL {
        recordingsURL.appendingPathComponent("recording-\(id.uuidString).mov")
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([rootURL])
    }
}
