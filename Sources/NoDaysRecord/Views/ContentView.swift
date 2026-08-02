import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            NDTheme.canvas.ignoresSafeArea()
            DotGridBackground()
                .opacity(0.42)

            HStack(spacing: 0) {
                SidebarView()
                Rectangle()
                    .fill(NDTheme.border.opacity(0.65))
                    .frame(width: 1)
                mainContent
            }
        }
        .task {
            await model.onAppear()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            TopBar()
            Rectangle()
                .fill(NDTheme.border.opacity(0.5))
                .frame(height: 1)

            switch model.section {
            case .recordings:
                RecordingsView()
            case .presets:
                PresetsView()
            case .settings:
                SettingsView()
            case .editor:
                if let recording = model.selectedRecording {
                    EditorView(recording: recording)
                } else {
                    RecordingsView()
                }
            }
        }
        .frame(minWidth: 1_050, minHeight: 650)
    }
}

struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            BrandMark()
                .padding(.top, 26)
                .padding(.bottom, 38)

            VStack(spacing: 8) {
                ForEach(AppSection.allCases.filter { $0 != .editor }) { section in
                    SidebarItem(section: section, isSelected: model.section == section) {
                        model.section = section
                        model.statusMessage = nil
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                StatusPill(
                    text: model.isRecording ? (model.isPaused ? "Paused" : "Live") : "Local",
                    tint: model.isRecording ? NDTheme.recording : NDTheme.success,
                    symbol: model.isRecording ? "record.circle" : "lock.fill"
                )
                .scaleEffect(0.9)
            }
            .padding(.bottom, 22)
        }
        .frame(width: 92)
        .background(.ultraThinMaterial.opacity(0.28))
    }
}

private struct BrandMark: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(NDTheme.accentGradient)
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(NDTheme.canvas)
            }
            .frame(width: 42, height: 42)
            .shadow(color: NDTheme.accent.opacity(0.16), radius: 14, y: 5)

            Text("NO/DAYS")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(NDTheme.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("NoDays Record")
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: section.symbol)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .frame(width: 36, height: 28)
                    .background(isSelected ? NDTheme.accentStrong : .clear, in: .rect(cornerRadius: 10))
                    .foregroundStyle(isSelected ? NDTheme.canvas : NDTheme.secondary)
                Text(section.title == "Recordings" ? "Library" : section.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? NDTheme.primary : NDTheme.tertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
        .accessibilityHint(section.detail)
        .help(section.detail)
    }
}

struct TopBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 16) {
            if model.section == .editor, let recording = model.selectedRecording {
                Button {
                    model.section = .recordings
                    model.selectedRecording = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NDTheme.secondary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(NDIconButtonStyle(fill: NDTheme.surface))
                .accessibilityLabel("Back to recordings")

                Text(recording.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
            } else {
                Text(model.section.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(NDTheme.primary)
            }

            StatusPill(text: "Local only", tint: NDTheme.success, symbol: "lock.fill")

            Spacer()

            if model.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(NDTheme.recording)
                        .frame(width: 7, height: 7)
                    Text(model.isPaused ? "Recording paused" : "Recording \(model.elapsed.noDaysTimestamp)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NDTheme.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(NDTheme.recording.opacity(0.08), in: Capsule())
                .overlay { Capsule().stroke(NDTheme.recording.opacity(0.22), lineWidth: 1) }
            } else {
                HStack(spacing: 7) {
                    Text("Start")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(NDTheme.tertiary)
                    Text("⌘ ⇧ R")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(NDTheme.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(NDTheme.surface, in: .rect(cornerRadius: 6))
                        .overlay { RoundedRectangle(cornerRadius: 6).stroke(NDTheme.border, lineWidth: 1) }
                }
            }

            Button {
                model.section = .settings
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(SecondaryButtonStyle(compact: true))
            .accessibilityLabel("Open Settings")
            .accessibilityHint(AppSection.settings.detail)
            .help(AppSection.settings.detail)
        }
        .padding(.horizontal, 28)
        .frame(height: 58)
    }
}
