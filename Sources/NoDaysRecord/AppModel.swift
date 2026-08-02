import AppKit
import AVFoundation
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var section: AppSection = .recordings
    var capture = CapturePreferences()
    var windowOptions: [WindowOption] = []
    var recordings: [Recording] = []
    var presets: [Preset] = []
    var selectedRecording: Recording?
    var isRecording = false
    var isPaused = false
    var elapsed: TimeInterval = 0
    var countdownRemaining: Int?
    var statusMessage: String?
    var isCaptioning = false
    var captionText: String?

    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let captureService: ScreenCaptureService
    @ObservationIgnored private let captionService: LocalCaptionService
    @ObservationIgnored private let shortcutMonitor: GlobalShortcutMonitor
    @ObservationIgnored private let areaSelectionController: AreaSelectionController
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var currentRecordingID: UUID?

    init() {
        store = LocalStore()
        captureService = ScreenCaptureService()
        captionService = LocalCaptionService()
        shortcutMonitor = GlobalShortcutMonitor()
        areaSelectionController = AreaSelectionController()

        recordings = store.loadRecordings()
        presets = store.loadPresets()
        loadPreferences()

        shortcutMonitor.start { [weak self] in
            Task { @MainActor [weak self] in
                await self?.toggleRecordingFromShortcut()
            }
        }
    }

    var selectedWindow: WindowOption? {
        guard let selectedWindowID = capture.selectedWindowID else { return nil }
        return windowOptions.first { $0.id == selectedWindowID }
    }

    var storageLocation: String {
        store.rootURL.path
    }

    var captureTargetReady: Bool {
        switch capture.source {
        case .screen:
            true
        case .window:
            selectedWindow != nil
        case .area:
            capture.selectedArea != nil
        }
    }

    func onAppear() async {
        await refreshWindows()
    }

    func refreshWindows() async {
        guard capture.source == .window else { return }
        do {
            windowOptions = try await captureService.loadWindowOptions()
            if let selectedWindowID = capture.selectedWindowID,
               !windowOptions.contains(where: { $0.id == selectedWindowID }) {
                capture.selectedWindowID = nil
            }
        } catch {
            windowOptions = []
            statusMessage = error.localizedDescription
        }
    }

    func chooseArea() {
        areaSelectionController.present { [weak self] rect in
            guard let self, let rect else { return }
            capture.selectedArea = AreaSelection(rect: rect)
            persistPreferences()
        }
    }

    func startRecording() async {
        guard !isRecording else { return }

        guard captureTargetReady else {
            statusMessage = capture.source == .window
                ? "Choose a visible window before recording."
                : "Choose an area before recording."
            return
        }

        statusMessage = nil
        captionText = nil

        if capture.faceCamEnabled {
            statusMessage = "Face-cam compositing is not enabled in this capture build yet. Turn it off to record a real screen movie."
            return
        }

        if capture.microphoneEnabled {
            let microphoneGranted = await ensureMicrophoneAccess()
            guard microphoneGranted else {
                statusMessage = "Microphone access was not granted. Enable it in System Settings, then try again."
                return
            }
        }

        persistPreferences()
        let recordingID = UUID()
        let outputURL = store.newRecordingURL(for: recordingID)
        currentRecordingID = recordingID

        if capture.countdownSeconds > 0 {
            for value in stride(from: capture.countdownSeconds, through: 1, by: -1) {
                countdownRemaining = value
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    countdownRemaining = nil
                    return
                }
            }
            countdownRemaining = nil
        }

        do {
            try await captureService.start(
                preferences: capture,
                windowOption: selectedWindow,
                area: capture.selectedArea,
                outputURL: outputURL
            )
            isRecording = true
            isPaused = false
            elapsed = 0
            statusMessage = "Recording locally"
            startTimer()
        } catch {
            countdownRemaining = nil
            currentRecordingID = nil
            statusMessage = error.localizedDescription
        }
    }

    func toggleRecordingFromShortcut() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }

    func togglePause() async {
        guard isRecording else { return }
        do {
            if isPaused {
                try await captureService.resume()
                isPaused = false
                statusMessage = "Recording locally"
            } else {
                try await captureService.pause()
                isPaused = true
                statusMessage = "Recording paused"
            }
        } catch {
            statusMessage = "Pause/resume is unavailable for this capture session: \(error.localizedDescription)"
        }
    }

    func stopRecording() async {
        guard isRecording else { return }
        timerTask?.cancel()
        timerTask = nil
        let result = await captureService.stop()
        isRecording = false
        isPaused = false
        statusMessage = nil

        guard let url = result.url, FileManager.default.fileExists(atPath: url.path) else {
            currentRecordingID = nil
            return
        }

        let asset = AVURLAsset(url: url)
        let assetDuration = (try? await asset.load(.duration))?.seconds ?? 0
        let duration = max(result.duration, assetDuration.isFinite ? assetDuration : 0)
        guard duration > 0 else {
            currentRecordingID = nil
            return
        }

        var dimensions = CGSize.zero
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
            dimensions = (try? await videoTrack.load(.naturalSize)) ?? .zero
        }
        let title = recordingTitle(for: Date())
        let recording = Recording(
            id: currentRecordingID ?? UUID(),
            title: title,
            filePath: url.path,
            createdAt: Date(),
            duration: duration,
            source: capture.source,
            width: Int(abs(dimensions.width)),
            height: Int(abs(dimensions.height))
        )
        recordings.insert(recording, at: 0)
        store.saveRecordings(recordings)
        currentRecordingID = nil
        selectedRecording = recording
        section = .editor
    }

    func open(_ recording: Recording) {
        guard recording.existsOnDisk else {
            statusMessage = "This recording is no longer on disk."
            recordings.removeAll { $0.id == recording.id }
            store.saveRecordings(recordings)
            return
        }
        selectedRecording = recording
        section = .editor
    }

    func delete(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
        } catch {
            statusMessage = "Could not remove this recording: \(error.localizedDescription)"
            return
        }
        recordings.removeAll { $0.id == recording.id }
        store.saveRecordings(recordings)
        if selectedRecording?.id == recording.id {
            selectedRecording = nil
            section = .recordings
        }
    }

    func savePreset(name: String, background: BackgroundStyle, cursor: CursorStyle, followCursor: Bool, captionStyle: CaptionStyle) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let preset = Preset(
            id: UUID(),
            name: trimmedName,
            background: background,
            cursor: cursor,
            followCursor: followCursor,
            captionStyle: captionStyle,
            createdAt: Date()
        )
        presets.append(preset)
        store.savePresets(presets)
    }

    func generateCaptions(for recording: Recording) async {
        guard !isCaptioning else { return }
        isCaptioning = true
        statusMessage = "Generating captions on this Mac…"
        do {
            captionText = try await captionService.generate(for: recording.fileURL)
            statusMessage = "Captions generated locally"
        } catch {
            statusMessage = error.localizedDescription
        }
        isCaptioning = false
    }

    func requestScreenAccess() {
        if CGPreflightScreenCaptureAccess() {
            statusMessage = "Screen Recording access is enabled."
        } else {
            _ = CGRequestScreenCaptureAccess()
            statusMessage = "If macOS did not show a prompt, enable NoDays Record in System Settings → Privacy & Security → Screen Recording, then relaunch."
        }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }

    func revealStorage() {
        store.revealInFinder()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard let self, !self.isPaused else { continue }
                self.elapsed += 1
            }
        }
    }

    private func ensureMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: "capturePreferences"),
              let stored = try? JSONDecoder().decode(CapturePreferences.self, from: data) else { return }
        capture = stored
    }

    private func persistPreferences() {
        guard let data = try? JSONEncoder().encode(capture) else { return }
        UserDefaults.standard.set(data, forKey: "capturePreferences")
    }

    private func recordingTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
