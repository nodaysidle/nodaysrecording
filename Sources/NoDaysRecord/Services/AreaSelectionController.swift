import AppKit
import Foundation

@MainActor
final class AreaSelectionController {
    private var panel: NSPanel?

    func present(completion: @escaping (CGRect?) -> Void) {
        dismissPanel()

        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let selectionView = AreaSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
        selectionView.onFinish = { [weak self] localRect in
            let globalRect = localRect.map { rect in
                rect.offsetBy(dx: screen.frame.minX, dy: screen.frame.minY)
            }
            self?.dismissPanel()
            completion(globalRect)
        }

        let panel = SelectionPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = selectionView
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(selectionView)
        self.panel = panel
    }

    private func dismissPanel() {
        guard let panel else { return }
        panel.close()
        self.panel = nil
    }
}

private final class SelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class AreaSelectionView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        guard let selection = normalizedSelection, selection.width > 12, selection.height > 12 else {
            onFinish?(nil)
            return
        }
        onFinish?(selection)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onFinish?(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.withAlphaComponent(0.58).setFill()
        dirtyRect.fill()

        guard let selection = normalizedSelection else {
            drawHint()
            return
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .clear
        selection.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor(calibratedRed: 0.91, green: 0.84, blue: 0.72, alpha: 1).setStroke()
        let border = NSBezierPath(rect: selection)
        border.lineWidth = 2
        border.stroke()

        let label = "\(Int(selection.width)) × \(Int(selection.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = label.size(withAttributes: attributes)
        let textRect = CGRect(
            x: selection.midX - textSize.width / 2 - 8,
            y: selection.maxY + 10,
            width: textSize.width + 16,
            height: textSize.height + 8
        )
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: textRect, xRadius: 6, yRadius: 6).fill()
        label.draw(in: textRect.insetBy(dx: 8, dy: 4), withAttributes: attributes)
    }

    private var normalizedSelection: CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }

    private func drawHint() {
        let label = "Drag to choose an area  ·  Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]
        let size = label.size(withAttributes: attributes)
        label.draw(
            at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
            withAttributes: attributes
        )
    }
}
