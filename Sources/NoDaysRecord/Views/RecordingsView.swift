import SwiftUI

struct RecordingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Make the next take count.")
                            .font(.system(size: 27, weight: .semibold, design: .rounded))
                            .foregroundStyle(NDTheme.primary)
                        Text("Choose what matters, then let NoDays Record keep the polish local.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(NDTheme.secondary)
                    }

                    CaptureSourceSection(source: $model.capture.source) {
                        if model.capture.source == .window {
                            Task { await model.refreshWindows() }
                        }
                    }

                    CaptureControlsPanel(model: model)

                    if let statusMessage = model.statusMessage {
                        StatusMessageView(text: statusMessage, isRecording: model.isRecording)
                    }

                    RecordAction(model: model)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
                .padding(.top, 34)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(NDTheme.border.opacity(0.62))
                .frame(width: 1)

            RecentRecordingsPanel()
                .frame(width: 350)
        }
        .overlay(alignment: .bottom) {
            if model.isRecording {
                RecordingTray()
                    .padding(.bottom, 18)
            }
            if let countdown = model.countdownRemaining {
                CountdownOverlay(number: countdown)
            }
        }
    }
}

private struct CaptureSourceSection: View {
    @Binding var source: CaptureSource
    let didSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionEyebrow(text: "Capture source", trailing: "Choose one real target")

            HStack(spacing: 12) {
                ForEach(CaptureSource.allCases) { candidate in
                    CaptureSourceCard(source: candidate, isSelected: candidate == source) {
                        source = candidate
                        didSelect()
                    }
                }
            }
        }
    }
}

private struct CaptureSourceCard: View {
    let source: CaptureSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: source.symbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? NDTheme.accentStrong : NDTheme.secondary)
                    Spacer()
                    if isSelected {
                        Circle()
                            .fill(NDTheme.accentStrong)
                            .frame(width: 7, height: 7)
                            .shadow(color: NDTheme.accentStrong.opacity(0.7), radius: 8)
                    }
                }
                Text(source.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? NDTheme.primary : NDTheme.secondary)
                Text(source.detail)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .padding(16)
            .background(isSelected ? NDTheme.accentStrong.opacity(0.065) : NDTheme.surface, in: .rect(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? NDTheme.accentStrong : NDTheme.border, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(source.title)
        .accessibilityHint(source.detail)
    }
}

private struct CaptureControlsPanel: View {
    @Bindable var model: AppModel

    var body: some View {
        GlassPanel(radius: 17) {
            VStack(alignment: .leading, spacing: 18) {
                SectionEyebrow(text: "Recording recipe", trailing: "Everything stays on this Mac")

                HStack(spacing: 26) {
                    VStack(spacing: 16) {
                        CaptureToggleRow(
                            symbol: "mic",
                            title: "Microphone",
                            detail: "Built-in or selected input",
                            isOn: $model.capture.microphoneEnabled
                        )
                        CaptureToggleRow(
                            symbol: "speaker.wave.2",
                            title: "System audio",
                            detail: "Include the sounds from your Mac",
                            isOn: $model.capture.systemAudioEnabled
                        )
                    }

                    VStack(spacing: 16) {
                        CaptureToggleRow(
                            symbol: "video",
                            title: "Face cam",
                            detail: "Requires a camera compositor",
                            isOn: $model.capture.faceCamEnabled
                        )
                        CountdownRow(selection: $model.capture.countdownSeconds)
                    }
                }

                if model.capture.source == .window {
                    WindowSelectionRow(options: model.windowOptions, selectedID: $model.capture.selectedWindowID)
                }

                if model.capture.source == .area {
                    AreaSelectionRow(area: model.capture.selectedArea, chooseArea: model.chooseArea)
                }
            }
            .padding(20)
        }
    }
}

private struct CaptureToggleRow: View {
    let symbol: String
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? NDTheme.accentStrong : NDTheme.tertiary)
                .frame(width: 30, height: 30)
                .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                .overlay { RoundedRectangle(cornerRadius: 9).stroke(NDTheme.border, lineWidth: 1) }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(NDTheme.accentStrong)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CountdownRow: View {
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 11) {
                Text(selection == 0 ? "—" : "\(selection)s")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(NDTheme.accentStrong)
                .frame(width: 30, height: 30)
                .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                .overlay { RoundedRectangle(cornerRadius: 9).stroke(NDTheme.border, lineWidth: 1) }

            VStack(alignment: .leading, spacing: 2) {
                Text("Countdown")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
                Text("Time to get ready")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
            }

            Spacer(minLength: 4)

            Picker("Countdown", selection: $selection) {
                Text("Off").tag(0)
                Text("3 sec").tag(3)
                Text("5 sec").tag(5)
                Text("10 sec").tag(10)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(NDTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WindowSelectionRow: View {
    let options: [WindowOption]
    @Binding var selectedID: UInt32?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "macwindow.on.rectangle")
                .foregroundStyle(NDTheme.accentStrong)
            VStack(alignment: .leading, spacing: 3) {
                Text("Window target")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
                Text(options.isEmpty ? "No visible windows found" : "Only the selected window will be captured")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
            }
            Spacer()
            Menu {
                ForEach(options) { option in
                    Button {
                        selectedID = option.id
                    } label: {
                        Text(option.displayTitle)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(options.first(where: { $0.id == selectedID })?.displayTitle ?? "Choose a window")
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(NDTheme.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                .overlay { RoundedRectangle(cornerRadius: 9).stroke(NDTheme.border, lineWidth: 1) }
            }
            .menuStyle(.borderlessButton)
            .disabled(options.isEmpty)
        }
        .padding(.top, 4)
    }
}

private struct AreaSelectionRow: View {
    let area: AreaSelection?
    let chooseArea: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.dashed.badge.record")
                .foregroundStyle(NDTheme.accentStrong)
            VStack(alignment: .leading, spacing: 3) {
                Text("Area target")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
                Text(area?.summary ?? "No area selected yet")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(area == nil ? NDTheme.tertiary : NDTheme.success)
            }
            Spacer()
            Button(area == nil ? "Choose area" : "Choose again", action: chooseArea)
                .buttonStyle(SecondaryButtonStyle(compact: true))
        }
        .padding(.top, 4)
    }
}

private struct StatusMessageView: View {
    let text: String
    let isRecording: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isRecording ? "waveform" : "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isRecording ? NDTheme.success : NDTheme.accentStrong)
            Text(text)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(NDTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background((isRecording ? NDTheme.success : NDTheme.accentStrong).opacity(0.07), in: .rect(cornerRadius: 11))
        .overlay {
            RoundedRectangle(cornerRadius: 11)
                .stroke((isRecording ? NDTheme.success : NDTheme.accentStrong).opacity(0.18), lineWidth: 1)
        }
    }
}

private struct RecordAction: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 9) {
            Button {
                Task { await model.startRecording() }
            } label: {
                HStack(spacing: 9) {
                    Circle()
                        .fill(NDTheme.recording)
                        .frame(width: 8, height: 8)
                    Text("Start recording")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(model.isRecording || model.countdownRemaining != nil || !model.captureTargetReady)

            Text("Global shortcut  \(model.capture.shortcutDisplay)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(NDTheme.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
}

private struct RecentRecordingsPanel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionEyebrow(text: "Recent takes")
                if !model.recordings.isEmpty {
                    Text("\(model.recordings.count)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(NDTheme.accentStrong)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(NDTheme.accentStrong.opacity(0.09), in: Capsule())
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 16)

            if model.recordings.isEmpty {
                EmptyRecordingsState()
                    .padding(.horizontal, 22)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.recordings) { recording in
                            RecordingRow(recording: recording) {
                                model.open(recording)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }

            PresetHint()
                .padding(18)
        }
        .background(.ultraThinMaterial.opacity(0.23))
    }
}

private struct EmptyRecordingsState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(NDTheme.accentDeep)
            Text("No recordings yet")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(NDTheme.primary)
            Text("Your first real take will appear here with its movie, duration, and capture source.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(NDTheme.tertiary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("Nothing is uploaded")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(NDTheme.success)
        }
        .padding(.top, 16)
    }
}

private struct RecordingRow: View {
    let recording: Recording
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                VideoThumbnail(recording: recording)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay { RoundedRectangle(cornerRadius: 10).stroke(NDTheme.border, lineWidth: 1) }

                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(recording.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(NDTheme.primary)
                            .lineLimit(1)
                        Text("\(recording.source.title)  ·  \(recording.createdAt.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(NDTheme.tertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NDTheme.accentStrong)
                }
            }
            .padding(10)
            .background(NDTheme.surface, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(NDTheme.border, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(recording.title) in editor")
    }
}

private struct PresetHint: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NDTheme.accentDeep)
                Text("Saved style")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundStyle(NDTheme.tertiary)
            }

            if let preset = model.presets.last {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(preset.name)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(NDTheme.primary)
                        Text("\(preset.background.title)  ·  \(preset.cursor.title) cursor")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(NDTheme.tertiary)
                    }
                    Spacer()
                    StatusPill(text: "Ready", tint: NDTheme.success)
                }
            } else {
                Text("Save a style from the editor to reuse your background, cursor, zoom, and caption choices.")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(NDTheme.surfaceStrong.opacity(0.72), in: .rect(cornerRadius: 13))
        .overlay { RoundedRectangle(cornerRadius: 13).stroke(NDTheme.accentDeep.opacity(0.22), lineWidth: 1) }
    }
}

private struct RecordingTray: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 15) {
            HStack(spacing: 8) {
                Circle()
                    .fill(NDTheme.recording)
                    .frame(width: 8, height: 8)
                Text(model.elapsed.noDaysTimestamp)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(NDTheme.primary)
            }

            Rectangle()
                .fill(NDTheme.border)
                .frame(width: 1, height: 18)

            Button {
                Task { await model.togglePause() }
            } label: {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(NDIconButtonStyle())
            .accessibilityLabel(model.isPaused ? "Resume recording" : "Pause recording")

            Button {
                Task { await model.stopRecording() }
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(NDIconButtonStyle(tint: NDTheme.recording, fill: NDTheme.recording.opacity(0.08)))
            .accessibilityLabel("Stop recording")

            Text(model.isPaused ? "Paused" : "Recording locally")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(model.isPaused ? NDTheme.accent : NDTheme.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .background(NDTheme.surfaceStrong, in: Capsule())
        .overlay { Capsule().stroke(NDTheme.borderStrong, lineWidth: 1) }
        .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
    }
}

private struct CountdownOverlay: View {
    let number: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.52).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Get ready")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.secondary)
                Text("\(number)")
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .foregroundStyle(NDTheme.accentStrong)
                Text("Recording starts next")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(NDTheme.tertiary)
            }
            .padding(34)
            .background(.regularMaterial, in: .rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(NDTheme.borderStrong, lineWidth: 1) }
        }
        .allowsHitTesting(false)
    }
}
