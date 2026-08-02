import AVFoundation
import AppKit
import SwiftUI

struct VideoThumbnail: View {
    let recording: Recording
    @State private var image: NSImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(NDTheme.surfaceStrong)
                        .overlay {
                            Image(systemName: "film.stack")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(NDTheme.tertiary)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            Text(recording.duration.noDaysTimestamp)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.black.opacity(0.68), in: .rect(cornerRadius: 6))
                .padding(8)
        }
        .task(id: recording.filePath) {
            await loadImage()
        }
    }

    private func loadImage() async {
        let asset = AVURLAsset(url: recording.fileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: min(max(recording.duration * 0.18, 0.1), 2), preferredTimescale: 600)
        let cgImage = await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { image, _, _ in
                continuation.resume(returning: image)
            }
        }
        guard let cgImage else { return }
        image = NSImage(cgImage: cgImage, size: .zero)
    }
}
