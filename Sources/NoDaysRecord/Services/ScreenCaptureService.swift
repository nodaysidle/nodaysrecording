import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case screenPermission
    case noDisplay
    case windowUnavailable
    case areaUnavailable
    case unsupportedConfiguration

    var errorDescription: String? {
        switch self {
        case .screenPermission:
            "Screen Recording permission is required. Open System Settings → Privacy & Security → Screen Recording, then relaunch NoDays Record."
        case .noDisplay:
            "No display is available to capture."
        case .windowUnavailable:
            "That window is no longer available. Choose another visible window."
        case .areaUnavailable:
            "Choose a capture area before starting."
        case .unsupportedConfiguration:
            "This Mac does not expose a compatible local recording format."
        }
    }
}

@MainActor
final class ScreenCaptureService: NSObject, SCRecordingOutputDelegate, SCStreamDelegate {
    private var stream: SCStream?
    private var recordingOutput: SCRecordingOutput?
    private var outputURL: URL?

    private(set) var isCapturing = false
    private(set) var isPaused = false

    func loadWindowOptions() async throws -> [WindowOption] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content.windows
            .filter { $0.isOnScreen && $0.windowLayer == 0 }
            .compactMap { window in
                guard let applicationName = window.owningApplication?.applicationName else { return nil }
                return WindowOption(
                    id: window.windowID,
                    title: window.title ?? "",
                    applicationName: applicationName,
                    frame: window.frame
                )
            }
            .filter { !$0.applicationName.isEmpty }
            .sorted { $0.displayTitle.localizedStandardCompare($1.displayTitle) == .orderedAscending }
    }

    func start(
        preferences: CapturePreferences,
        windowOption: WindowOption?,
        area: AreaSelection?,
        outputURL: URL
    ) async throws {
        guard CGPreflightScreenCaptureAccess() else {
            _ = CGRequestScreenCaptureAccess()
            throw CaptureError.screenPermission
        }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) ?? content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter: SCContentFilter
        let captureSize: CGSize
        var sourceRect: CGRect?

        switch preferences.source {
        case .screen:
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            captureSize = CGSize(width: display.width, height: display.height)
        case .window:
            guard let windowOption,
                  let window = content.windows.first(where: { $0.windowID == windowOption.id }) else {
                throw CaptureError.windowUnavailable
            }
            filter = SCContentFilter(desktopIndependentWindow: window)
            let scale = scaleFactor(for: window.frame)
            captureSize = CGSize(width: max(2, window.frame.width * scale), height: max(2, window.frame.height * scale))
        case .area:
            guard let area, area.rect.width > 2, area.rect.height > 2 else {
                throw CaptureError.areaUnavailable
            }
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let displayFrame = display.frame
            sourceRect = CGRect(
                x: area.rect.minX - displayFrame.minX,
                y: area.rect.minY - displayFrame.minY,
                width: area.rect.width,
                height: area.rect.height
            )
            let scale = scaleFactor(for: displayFrame)
            captureSize = CGSize(width: max(2, area.rect.width * scale), height: max(2, area.rect.height * scale))
        }

        let configuration = SCStreamConfiguration()
        configuration.width = Int(captureSize.width.rounded())
        configuration.height = Int(captureSize.height.rounded())
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 5
        configuration.showsCursor = true
        configuration.capturesAudio = preferences.systemAudioEnabled || preferences.microphoneEnabled
        configuration.captureMicrophone = preferences.microphoneEnabled
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2
        if let sourceRect {
            configuration.sourceRect = sourceRect
        }

        let recordingConfiguration = SCRecordingOutputConfiguration()
        guard recordingConfiguration.availableOutputFileTypes.contains(.mov) else {
            throw CaptureError.unsupportedConfiguration
        }
        recordingConfiguration.outputURL = outputURL
        recordingConfiguration.outputFileType = .mov
        if recordingConfiguration.availableVideoCodecTypes.contains(.h264) {
            recordingConfiguration.videoCodecType = .h264
        }
        let newOutput = SCRecordingOutput(configuration: recordingConfiguration, delegate: self)
        let newStream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try newStream.addRecordingOutput(newOutput)
        try await startCapture(newStream)

        stream = newStream
        recordingOutput = newOutput
        self.outputURL = outputURL
        isCapturing = true
        isPaused = false
    }

    func pause() async throws {
        guard let stream, isCapturing, !isPaused else { return }
        try await stopCapture(stream)
        isPaused = true
    }

    func resume() async throws {
        guard let stream, isCapturing, isPaused else { return }
        try await startCapture(stream)
        isPaused = false
    }

    func stop() async -> (url: URL?, duration: TimeInterval) {
        guard let stream else {
            let url = outputURL
            reset()
            return (url, 0)
        }

        try? await stopCapture(stream)
        if let recordingOutput {
            try? stream.removeRecordingOutput(recordingOutput)
        }
        let duration = recordingOutput?.recordedDuration.seconds ?? 0
        let url = outputURL
        reset()
        return (url, duration.isFinite ? duration : 0)
    }

    func reset() {
        stream = nil
        recordingOutput = nil
        outputURL = nil
        isCapturing = false
        isPaused = false
    }

    nonisolated func recordingOutputDidStartRecording(_ recordingOutput: SCRecordingOutput) {
        // The model updates immediately after startCapture succeeds. This delegate exists
        // so the service remains compatible with the framework's recording lifecycle.
    }

    nonisolated func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        // The final duration is read synchronously after stopCapture completes.
    }

    nonisolated func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: any Error) {
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.reset()
            _ = message
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
        Task { @MainActor [weak self] in
            self?.isCapturing = false
            self?.isPaused = false
            _ = error
        }
    }

    private func startCapture(_ stream: SCStream) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stream.startCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func stopCapture(_ stream: SCStream) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stream.stopCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func scaleFactor(for rect: CGRect) -> CGFloat {
        NSScreen.screens.first(where: { $0.frame.intersects(rect) })?.backingScaleFactor ?? 2
    }
}
