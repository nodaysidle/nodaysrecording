import AVFoundation
import SwiftUI

struct EditorView: View {
    @Environment(AppModel.self) private var model
    let recording: Recording

    @State private var player: AVPlayer
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var zoomMarkers: [ZoomMarker] = []
    @State private var followCursor = true
    @State private var cursorStyle: CursorStyle = .halo
    @State private var background: BackgroundStyle = .graphite
    @State private var captionStyle: CaptionStyle = .none
    @State private var isSavePresetPresented = false
    @State private var presetName = ""

    init(recording: Recording) {
        self.recording = recording
        _player = State(initialValue: AVPlayer(url: recording.fileURL))
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                EditorStage(
                    player: player,
                    background: background,
                    cursorStyle: cursorStyle,
                    zoomScale: activeZoomScale
                )
                .padding(.horizontal, 28)
                .padding(.top, 26)

                EditorTimeline(
                    currentTime: $currentTime,
                    duration: duration,
                    markers: zoomMarkers,
                    onSeek: seek
                )
                .padding(.horizontal, 28)
                .padding(.top, 18)

                HStack(spacing: 10) {
                    Button {
                        player.play()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(NDIconButtonStyle(tint: NDTheme.canvas, fill: NDTheme.accentStrong))
                    .accessibilityLabel("Play recording")

                    Text(currentTime.noDaysTimestamp)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NDTheme.secondary)
                    Text("of")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(NDTheme.tertiary)
                    Text(duration.noDaysTimestamp)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NDTheme.secondary)

                    Spacer()

                    StatusPill(text: "Original movie", tint: NDTheme.success, symbol: "film")
                }
                .padding(.horizontal, 28)
                .padding(.top, 10)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(NDTheme.border.opacity(0.62))
                .frame(width: 1)

            EditorInspector(
                duration: duration,
                currentTime: currentTime,
                zoomMarkers: $zoomMarkers,
                followCursor: $followCursor,
                cursorStyle: $cursorStyle,
                background: $background,
                captionStyle: $captionStyle,
                isCaptioning: model.isCaptioning,
                captionText: model.captionText,
                addZoom: addZoom,
                generateCaptions: { Task { await model.generateCaptions(for: recording) } },
                savePreset: { isSavePresetPresented = true }
            )
            .frame(width: 300)
        }
        .sheet(isPresented: $isSavePresetPresented) {
            SavePresetSheet(
                name: $presetName,
                background: background,
                cursor: cursorStyle,
                followCursor: followCursor,
                captionStyle: captionStyle,
                save: savePreset,
                cancel: { isSavePresetPresented = false }
            )
        }
        .task {
            let asset = AVURLAsset(url: recording.fileURL)
            let assetDuration = (try? await asset.load(.duration))?.seconds ?? 0
            duration = max(recording.duration, assetDuration)
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            guard let time = player.currentItem?.currentTime().seconds, time.isFinite else { return }
            currentTime = max(0, time)
        }
    }

    private var activeZoomScale: Double {
        zoomMarkers.filter { $0.time <= currentTime }.last?.scale ?? 1
    }

    private func seek(_ time: TimeInterval) {
        currentTime = time
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    private func addZoom() {
        let marker = ZoomMarker(id: UUID(), time: currentTime, scale: 1.24)
        zoomMarkers.append(marker)
        zoomMarkers.sort { $0.time < $1.time }
    }

    private func savePreset() {
        model.savePreset(
            name: presetName,
            background: background,
            cursor: cursorStyle,
            followCursor: followCursor,
            captionStyle: captionStyle
        )
        presetName = ""
        isSavePresetPresented = false
    }
}

private struct EditorStage: View {
    let player: AVPlayer
    let background: BackgroundStyle
    let cursorStyle: CursorStyle
    let zoomScale: Double

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            PlayerSurface(player: player)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NDTheme.borderStrong, lineWidth: 1)
                }
                .scaleEffect(zoomScale)
                .animation(.easeOut(duration: 0.2), value: zoomScale)
                .padding(12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 7) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 10, weight: .semibold))
                Text(cursorStyle.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(NDTheme.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.black.opacity(0.45), in: Capsule())
            .padding(14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(NDTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 28, y: 14)
    }

    private var backgroundColor: some View {
        switch background {
        case .graphite:
            AnyView(NDTheme.surfaceStrong)
        case .sand:
            AnyView(LinearGradient(colors: [NDTheme.accentDeep.opacity(0.42), NDTheme.canvas], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .smoke:
            AnyView(LinearGradient(colors: [Color.white.opacity(0.12), NDTheme.canvas], startPoint: .top, endPoint: .bottom))
        }
    }
}

private struct PlayerSurface: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerSurfaceView {
        let view = PlayerSurfaceView()
        view.player = player
        return view
    }

    func updateNSView(_ nsView: PlayerSurfaceView, context: Context) {
        nsView.player = player
    }

    static func dismantleNSView(_ nsView: PlayerSurfaceView, coordinator: ()) {
        nsView.player = nil
    }
}

private final class PlayerSurfaceView: NSView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayer()
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    private func configureLayer() {
        wantsLayer = true
        layer = playerLayer
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = NSColor.clear.cgColor
    }
}

private struct EditorTimeline: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let markers: [ZoomMarker]
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(NDTheme.surfaceStrong)
                    .frame(height: 58)
                GeometryReader { proxy in
                    ForEach(markers) { marker in
                        let x = duration > 0 ? proxy.size.width * marker.time / duration : 0
                        VStack(spacing: 3) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(NDTheme.accentStrong)
                            Rectangle()
                                .fill(NDTheme.accentStrong.opacity(0.54))
                                .frame(width: 1, height: 31)
                        }
                        .position(x: min(max(x, 8), max(proxy.size.width - 8, 8)), y: 29)
                    }

                    Rectangle()
                        .fill(NDTheme.accentStrong)
                        .frame(width: 2, height: 48)
                        .position(
                            x: duration > 0 ? min(max(proxy.size.width * currentTime / duration, 1), max(proxy.size.width - 1, 1)) : 1,
                            y: 29
                        )
                }
                .frame(height: 58)
                .allowsHitTesting(false)

                Slider(value: Binding(
                    get: { currentTime },
                    set: { onSeek($0) }
                ), in: 0...max(duration, 0.01))
                .tint(NDTheme.accentStrong.opacity(0.75))
                .padding(.horizontal, 9)
                .opacity(0.02)
            }
            .clipShape(.rect(cornerRadius: 8))

            HStack {
                Text("0:00")
                Spacer()
                Text(duration.noDaysTimestamp)
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(NDTheme.tertiary)
        }
    }
}

private struct EditorInspector: View {
    let duration: TimeInterval
    let currentTime: TimeInterval
    @Binding var zoomMarkers: [ZoomMarker]
    @Binding var followCursor: Bool
    @Binding var cursorStyle: CursorStyle
    @Binding var background: BackgroundStyle
    @Binding var captionStyle: CaptionStyle
    let isCaptioning: Bool
    let captionText: String?
    let addZoom: () -> Void
    let generateCaptions: () -> Void
    let savePreset: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                InspectorSection(title: "Zooms") {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Focus at playhead")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(NDTheme.primary)
                            Text(zoomMarkers.isEmpty ? "No zoom markers yet" : "\(zoomMarkers.count) marker\(zoomMarkers.count == 1 ? "" : "s") in this take")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(NDTheme.tertiary)
                        }
                        Spacer()
                        Button {
                            addZoom()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(NDIconButtonStyle(tint: NDTheme.canvas, fill: NDTheme.accentStrong))
                        .accessibilityLabel("Add zoom at current time")
                    }
                }

                InspectorSection(title: "Cursor") {
                    Toggle("Follow cursor", isOn: $followCursor)
                        .toggleStyle(.switch)
                        .tint(NDTheme.accentStrong)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(NDTheme.primary)
                    Picker("Cursor style", selection: $cursorStyle) {
                        ForEach(CursorStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tint(NDTheme.secondary)
                }

                InspectorSection(title: "Background") {
                    HStack(spacing: 8) {
                        ForEach(BackgroundStyle.allCases) { style in
                            BackgroundChoice(style: style, isSelected: background == style) {
                                background = style
                            }
                        }
                    }
                }

                InspectorSection(title: "Captions") {
                    Picker("Caption style", selection: $captionStyle) {
                        ForEach(CaptionStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tint(NDTheme.secondary)

                    if let captionText {
                        Text(captionText)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(NDTheme.secondary)
                            .lineLimit(4)
                            .padding(10)
                            .background(NDTheme.surfaceStrong, in: .rect(cornerRadius: 9))
                    } else {
                        Text("No caption track yet")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(NDTheme.tertiary)
                    }

                    Button {
                        generateCaptions()
                    } label: {
                        Label(isCaptioning ? "Generating…" : "Generate locally", systemImage: "waveform")
                    }
                    .buttonStyle(SecondaryButtonStyle(compact: true))
                    .disabled(isCaptioning)
                }

                Button {
                    savePreset()
                } label: {
                    Label("Save style as preset", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(PrimaryButtonStyle(compact: true))
            }
            .padding(22)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial.opacity(0.23))
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.25)
                .foregroundStyle(NDTheme.tertiary)
            content
        }
    }
}

private struct BackgroundChoice: View {
    let style: BackgroundStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(fill)
                    .frame(height: 36)
                    .overlay { RoundedRectangle(cornerRadius: 7).stroke(isSelected ? NDTheme.accentStrong : NDTheme.border, lineWidth: isSelected ? 1.5 : 1) }
                Text(style.title)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? NDTheme.primary : NDTheme.tertiary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var fill: some ShapeStyle {
        switch style {
        case .graphite: return AnyShapeStyle(NDTheme.surfaceStrong)
        case .sand: return AnyShapeStyle(LinearGradient(colors: [NDTheme.accentDeep, NDTheme.accentStrong], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .smoke: return AnyShapeStyle(LinearGradient(colors: [Color.white.opacity(0.20), NDTheme.canvas], startPoint: .top, endPoint: .bottom))
        }
    }
}

private struct SavePresetSheet: View {
    @Binding var name: String
    let background: BackgroundStyle
    let cursor: CursorStyle
    let followCursor: Bool
    let captionStyle: CaptionStyle
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Save your style")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(NDTheme.primary)
            Text("Reuse these editor choices on the next real recording.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(NDTheme.secondary)

            TextField("Preset name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 7) {
                StatusPill(text: background.title, tint: NDTheme.accent)
                StatusPill(text: cursor.title, tint: NDTheme.secondary)
                if followCursor { StatusPill(text: "Follow cursor", tint: NDTheme.success) }
                if captionStyle != .none { StatusPill(text: captionStyle.title + " captions", tint: NDTheme.accentDeep) }
            }

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .buttonStyle(SecondaryButtonStyle(compact: true))
                Button("Save preset", action: save)
                    .buttonStyle(PrimaryButtonStyle(compact: true))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 390)
        .background(NDTheme.canvas)
    }
}
