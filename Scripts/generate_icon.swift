import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard let outputFlag = arguments.firstIndex(of: "--output"),
      arguments.indices.contains(outputFlag + 1) else {
    fputs("Usage: generate_icon.swift --output <iconset-directory>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: arguments[outputFlag + 1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconFiles: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: alpha)
}

func drawIcon(size: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    let canvas = CGFloat(size)
    let iconRect = CGRect(x: 1, y: 1, width: canvas - 2, height: canvas - 2)
    let cornerRadius = canvas * 0.245
    let iconPath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    context.saveGState()
    context.beginPath()
    context.addPath(iconPath)
    context.clip()

    let backgroundGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0.17, 0.17, 0.16), color(0.055, 0.055, 0.06)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: canvas * 0.18, y: canvas * 0.92),
        end: CGPoint(x: canvas * 0.82, y: canvas * 0.05),
        options: []
    )

    context.restoreGState()

    context.saveGState()
    context.beginPath()
    context.addPath(iconPath)
    context.clip()
    context.beginPath()
    context.addPath(iconPath)
    context.setStrokeColor(color(1, 1, 1, 0.16))
    context.setLineWidth(max(1, canvas * 0.012))
    context.strokePath()
    context.restoreGState()

    let gold = color(0.91, 0.68, 0.35)
    let goldHighlight = color(0.98, 0.79, 0.47)
    let shadow = color(0, 0, 0, 0.42)

    func trianglePath() -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: canvas * 0.32, y: canvas * 0.20))
        path.addLine(to: CGPoint(x: canvas * 0.77, y: canvas * 0.50))
        path.addLine(to: CGPoint(x: canvas * 0.32, y: canvas * 0.80))
        path.closeSubpath()
        return path
    }

    func audioPath() -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: canvas * 0.19, y: canvas * 0.50))
        path.addLine(to: CGPoint(x: canvas * 0.31, y: canvas * 0.50))
        path.addCurve(
            to: CGPoint(x: canvas * 0.44, y: canvas * 0.50),
            control1: CGPoint(x: canvas * 0.34, y: canvas * 0.50),
            control2: CGPoint(x: canvas * 0.36, y: canvas * 0.50)
        )
        path.addCurve(
            to: CGPoint(x: canvas * 0.49, y: canvas * 0.25),
            control1: CGPoint(x: canvas * 0.45, y: canvas * 0.50),
            control2: CGPoint(x: canvas * 0.46, y: canvas * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: canvas * 0.55, y: canvas * 0.75),
            control1: CGPoint(x: canvas * 0.51, y: canvas * 0.25),
            control2: CGPoint(x: canvas * 0.52, y: canvas * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: canvas * 0.62, y: canvas * 0.34),
            control1: CGPoint(x: canvas * 0.58, y: canvas * 0.75),
            control2: CGPoint(x: canvas * 0.59, y: canvas * 0.34)
        )
        path.addCurve(
            to: CGPoint(x: canvas * 0.70, y: canvas * 0.50),
            control1: CGPoint(x: canvas * 0.64, y: canvas * 0.34),
            control2: CGPoint(x: canvas * 0.66, y: canvas * 0.50)
        )
        return path
    }

    func stroke(_ path: CGPath, color: CGColor, width: CGFloat) {
        context.saveGState()
        context.beginPath()
        context.addPath(path)
        context.setStrokeColor(color)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()
    }

    let markWidth = max(1.6, canvas * 0.095)
    let triangle = trianglePath()
    stroke(triangle, color: shadow, width: markWidth + max(1, canvas * 0.016))
    stroke(triangle, color: gold, width: markWidth)

    let waveform = audioPath()
    stroke(waveform, color: shadow, width: max(1.6, canvas * 0.078) + max(1, canvas * 0.014))
    stroke(waveform, color: goldHighlight, width: max(1.6, canvas * 0.078))

    let dotCenter = CGPoint(x: canvas * 0.78, y: canvas * 0.23)
    context.setFillColor(color(0, 0, 0, 0.35))
    context.fillEllipse(in: CGRect(x: dotCenter.x - canvas * 0.058 + canvas * 0.01, y: dotCenter.y - canvas * 0.058 - canvas * 0.01, width: canvas * 0.116, height: canvas * 0.116))
    context.setFillColor(color(0.98, 0.31, 0.25))
    context.fillEllipse(in: CGRect(x: dotCenter.x - canvas * 0.058, y: dotCenter.y - canvas * 0.058, width: canvas * 0.116, height: canvas * 0.116))

    return context.makeImage()
}

for iconFile in iconFiles {
    guard let image = drawIcon(size: iconFile.pixels) else {
        throw NSError(domain: "NoDaysRecordIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to render \(iconFile.name)"])
    }

    let outputURL = outputDirectory.appendingPathComponent(iconFile.name)
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "NoDaysRecordIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create \(outputURL.path)"])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "NoDaysRecordIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to write \(outputURL.path)"])
    }
}
