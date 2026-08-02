import CoreGraphics
import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case recordings
    case presets
    case settings
    case editor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recordings: "Recordings"
        case .presets: "Presets"
        case .settings: "Settings"
        case .editor: "Editor"
        }
    }

    var detail: String {
        switch self {
        case .recordings: "Capture a screen, window, or selected area."
        case .presets: "Reuse saved background, cursor, zoom, and caption styles."
        case .settings: "Manage permissions, storage, and local caption availability."
        case .editor: "Refine a real recording on this Mac."
        }
    }

    var symbol: String {
        switch self {
        case .recordings: "rectangle.inset.filled.and.person.filled"
        case .presets: "wand.and.stars"
        case .settings: "slider.horizontal.3"
        case .editor: "film"
        }
    }
}

enum CaptureSource: String, CaseIterable, Codable, Identifiable {
    case screen
    case window
    case area

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screen: "Entire screen"
        case .window: "A window"
        case .area: "Selected area"
        }
    }

    var detail: String {
        switch self {
        case .screen: "Capture one display at full resolution."
        case .window: "Follow one visible app window."
        case .area: "Draw a precise region on your desktop."
        }
    }

    var symbol: String {
        switch self {
        case .screen: "display"
        case .window: "macwindow"
        case .area: "viewfinder"
        }
    }
}

struct AreaSelection: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.width
        height = rect.height
    }

    var summary: String {
        "\(Int(width)) × \(Int(height)) px"
    }
}

struct CapturePreferences: Codable, Sendable {
    var source: CaptureSource = .screen
    var microphoneEnabled = true
    var systemAudioEnabled = false
    var faceCamEnabled = false
    var countdownSeconds = 3
    var selectedWindowID: UInt32?
    var selectedArea: AreaSelection?
    var shortcutDisplay = "⌘ ⇧ R"
}

struct WindowOption: Identifiable, Hashable, Sendable {
    let id: UInt32
    let title: String
    let applicationName: String
    let frame: CGRect

    var displayTitle: String {
        if title.isEmpty { return applicationName }
        return "\(applicationName) — \(title)"
    }
}

struct Recording: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var filePath: String
    var createdAt: Date
    var duration: TimeInterval
    var source: CaptureSource
    var width: Int
    var height: Int

    var fileURL: URL { URL(fileURLWithPath: filePath) }
    var existsOnDisk: Bool { FileManager.default.fileExists(atPath: filePath) }
}

struct Preset: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var background: BackgroundStyle
    var cursor: CursorStyle
    var followCursor: Bool
    var captionStyle: CaptionStyle
    var createdAt: Date
}

enum BackgroundStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case graphite
    case sand
    case smoke

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphite: "Graphite"
        case .sand: "Warm sand"
        case .smoke: "Soft smoke"
        }
    }
}

enum CursorStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case clean
    case halo
    case spotlight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: "Clean"
        case .halo: "Halo"
        case .spotlight: "Spotlight"
        }
    }
}

enum CaptionStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case quiet
    case bold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Off"
        case .quiet: "Quiet"
        case .bold: "Bold"
        }
    }
}

struct ZoomMarker: Identifiable, Hashable, Sendable {
    let id: UUID
    var time: TimeInterval
    var scale: Double
}

extension TimeInterval {
    var noDaysTimestamp: String {
        let totalSeconds = max(0, Int(self.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
