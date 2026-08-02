import AppKit
import SwiftUI

@main
@MainActor
struct NoDaysRecordApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1_380, height: 880)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Start or stop recording") {
                    Task { @MainActor in
                        await model.toggleRecordingFromShortcut()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: 1_140, height: 720)
            window.backgroundColor = NSColor(NDTheme.canvas)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
