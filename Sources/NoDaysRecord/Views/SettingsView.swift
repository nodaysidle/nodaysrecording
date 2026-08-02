import AVFoundation
import CoreGraphics
import SwiftUI
import Speech

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var screenAccess = false
    @State private var microphoneAccess = AVCaptureDevice.authorizationStatus(for: .audio)
    @State private var cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var speechAccess = SFSpeechRecognizer.authorizationStatus()
    @State private var onDeviceCaptions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions and storage.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(NDTheme.primary)
                    Text("Manage Screen Recording, microphone, camera, on-device captions, and where local movies live.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(NDTheme.secondary)
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionEyebrow(text: "Permissions", trailing: "macOS controls access")
                        PermissionRow(
                            symbol: "rectangle.inset.filled.and.person.filled",
                            title: "Screen Recording",
                            detail: "Required for displays, windows, and selected areas.",
                            state: screenAccess ? "Enabled" : "Needs access",
                            tint: screenAccess ? NDTheme.success : NDTheme.accentStrong,
                            actionTitle: screenAccess ? nil : "Open settings",
                            action: model.openPrivacySettings
                        )
                        PermissionRow(
                            symbol: "mic",
                            title: "Microphone",
                            detail: "Requested only when microphone capture is enabled.",
                            state: microphoneAccess == .authorized ? "Enabled" : permissionLabel(microphoneAccess),
                            tint: microphoneAccess == .authorized ? NDTheme.success : NDTheme.secondary,
                            actionTitle: microphoneAccess == .authorized ? nil : "Open settings",
                            action: model.openPrivacySettings
                        )
                        PermissionRow(
                            symbol: "video",
                            title: "Camera",
                            detail: "Reserved for the face-cam compositor.",
                            state: cameraAccess == .authorized ? "Enabled" : permissionLabel(cameraAccess),
                            tint: cameraAccess == .authorized ? NDTheme.success : NDTheme.secondary,
                            actionTitle: cameraAccess == .authorized ? nil : "Open settings",
                            action: model.openPrivacySettings
                        )
                        PermissionRow(
                            symbol: "waveform",
                            title: "On-device captions",
                            detail: "Speech Recognition is kept local when this language supports it.",
                            state: onDeviceCaptions ? "Available" : permissionLabel(speechAccess),
                            tint: onDeviceCaptions ? NDTheme.success : NDTheme.secondary,
                            actionTitle: speechAccess == .authorized ? nil : "Open settings",
                            action: model.openPrivacySettings
                        )
                    }
                    .padding(20)
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionEyebrow(text: "Storage", trailing: "Local files")
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(NDTheme.accentStrong)
                                .frame(width: 30, height: 30)
                                .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recording library")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(NDTheme.primary)
                                Text(model.storageLocation)
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .foregroundStyle(NDTheme.tertiary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            Button("Reveal", action: model.revealStorage)
                                .buttonStyle(SecondaryButtonStyle(compact: true))
                        }
                    }
                    .padding(20)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(NDTheme.success)
                    Text("NoDays Record does not upload captured media, audio, camera frames, or caption text. Export and sharing are explicit actions you control.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(NDTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(NDTheme.success.opacity(0.06), in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(NDTheme.success.opacity(0.18), lineWidth: 1) }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(36)
        }
        .scrollIndicators(.hidden)
        .task { refreshPermissions() }
    }

    private func refreshPermissions() {
        screenAccess = CGPreflightScreenCaptureAccess()
        microphoneAccess = AVCaptureDevice.authorizationStatus(for: .audio)
        cameraAccess = AVCaptureDevice.authorizationStatus(for: .video)
        speechAccess = SFSpeechRecognizer.authorizationStatus()
        onDeviceCaptions = speechAccess == .authorized && (SFSpeechRecognizer(locale: Locale.current)?.supportsOnDeviceRecognition ?? false)
    }

    private func permissionLabel(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Enabled"
        case .notDetermined: "Not requested"
        case .denied: "Denied"
        case .restricted: "Restricted"
        @unknown default: "Unavailable"
        }
    }

    private func permissionLabel(_ status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status {
        case .authorized: "Authorized"
        case .notDetermined: "Not requested"
        case .denied: "Denied"
        case .restricted: "Restricted"
        @unknown default: "Unavailable"
        }
    }
}

private struct PermissionRow: View {
    let symbol: String
    let title: String
    let detail: String
    let state: String
    let tint: Color
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                .overlay { RoundedRectangle(cornerRadius: 9).stroke(NDTheme.border, lineWidth: 1) }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatusPill(text: state, tint: tint)
                if let actionTitle {
                    Button(actionTitle, action: action)
                        .buttonStyle(SecondaryButtonStyle(compact: true))
                }
            }
        }
    }
}
