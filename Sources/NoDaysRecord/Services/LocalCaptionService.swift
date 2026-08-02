import Foundation
import Speech

enum CaptionError: LocalizedError {
    case notAuthorized
    case unavailable
    case noSpeechFound

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            "Speech Recognition permission is required for local captions."
        case .unavailable:
            "On-device captions are not available for the current language on this Mac."
        case .noSpeechFound:
            "No speech was detected in this recording."
        }
    }
}

@MainActor
final class LocalCaptionService {
    func generate(for url: URL) async throws -> String {
        let authorization = await requestAuthorization()
        guard authorization == .authorized else {
            throw CaptionError.notAuthorized
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable,
              recognizer.supportsOnDeviceRecognition else {
            throw CaptionError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true

        return try await withCheckedThrowingContinuation { continuation in
            var recognitionTask: SFSpeechRecognitionTask?
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    recognitionTask?.cancel()
                    return
                }
                guard let result, result.isFinal else { return }
                let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                if transcript.isEmpty {
                    continuation.resume(throwing: CaptionError.noSpeechFound)
                } else {
                    continuation.resume(returning: transcript)
                }
                recognitionTask?.cancel()
            }
        }
    }

    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
