import SwiftUI

enum NDTheme {
    static let canvas = Color(hex: 0x090B0F)
    static let surface = Color.white.opacity(0.045)
    static let surfaceStrong = Color(hex: 0x151820)
    static let border = Color.white.opacity(0.10)
    static let borderStrong = Color.white.opacity(0.18)
    static let primary = Color(hex: 0xF7F4EE)
    static let secondary = Color(hex: 0xA9A6A0)
    static let tertiary = Color(hex: 0x73716D)
    static let accent = Color(hex: 0xC9B8A0)
    static let accentStrong = Color(hex: 0xE8D5B7)
    static let accentDeep = Color(hex: 0xA78B71)
    static let recording = Color(hex: 0xF06B5C)
    static let success = Color(hex: 0x9EBFA4)

    static let accentGradient = LinearGradient(
        colors: [accentStrong, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

struct DotGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 32
            for x in stride(from: 0, through: size.width, by: step) {
                for y in stride(from: 0, through: size.height, by: step) {
                    let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1))
                    context.fill(dot, with: .color(.white.opacity(0.07)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct GlassPanel<Content: View>: View {
    let radius: CGFloat
    @ViewBuilder let content: Content

    init(radius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial, in: .rect(cornerRadius: radius))
            .background(NDTheme.surface, in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(NDTheme.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
    }
}

struct SectionEyebrow: View {
    let text: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(NDTheme.tertiary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(NDTheme.accentDeep)
            }
        }
    }
}

struct NDIconButtonStyle: ButtonStyle {
    var tint: Color = NDTheme.secondary
    var fill: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(fill, in: .rect(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .rounded))
            .foregroundStyle(NDTheme.canvas)
            .padding(.horizontal, compact ? 14 : 20)
            .padding(.vertical, compact ? 9 : 13)
            .background(NDTheme.accentGradient, in: .rect(cornerRadius: compact ? 10 : 12))
            .shadow(color: NDTheme.accent.opacity(0.14), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 12, weight: .medium, design: .rounded))
            .foregroundStyle(NDTheme.primary)
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 8 : 11)
            .background(NDTheme.surface, in: .rect(cornerRadius: compact ? 10 : 12))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 10 : 12)
                    .stroke(NDTheme.border, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct StatusPill: View {
    let text: String
    var tint: Color = NDTheme.secondary
    var symbol: String?

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(tint.opacity(0.08), in: Capsule())
        .overlay { Capsule().stroke(tint.opacity(0.22), lineWidth: 1) }
    }
}
