import SwiftUI

struct PresetsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save your recording style.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(NDTheme.primary)
                    Text("Reuse background, cursor, zoom, and caption choices on future recordings. Presets stay on this Mac and are created from the editor.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(NDTheme.secondary)
                }

                if model.presets.isEmpty {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 25, weight: .light))
                                .foregroundStyle(NDTheme.accentDeep)
                            Text("No saved presets")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(NDTheme.primary)
                            Text("Open a real recording in the editor, tune its background, cursor, zooms, and captions, then save those choices here.")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(NDTheme.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Back to recordings") {
                                model.section = .recordings
                            }
                            .buttonStyle(SecondaryButtonStyle(compact: true))
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: 560, alignment: .leading)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                        ForEach(model.presets) { preset in
                            PresetCard(preset: preset)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(36)
        }
        .scrollIndicators(.hidden)
    }
}

private struct PresetCard: View {
    let preset: Preset

    var body: some View {
        GlassPanel(radius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(preset.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(NDTheme.primary)
                    Spacer()
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(NDTheme.success)
                }

                HStack(spacing: 8) {
                    PresetToken(label: "Background", value: preset.background.title)
                    PresetToken(label: "Cursor", value: preset.cursor.title)
                }
                HStack(spacing: 8) {
                    PresetToken(label: "Follow", value: preset.followCursor ? "On" : "Off")
                    PresetToken(label: "Captions", value: preset.captionStyle.title)
                }
            }
            .padding(18)
        }
    }
}

private struct PresetToken: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(NDTheme.tertiary)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(NDTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
