//
//  MenuBarIcon.swift
//  VPN Splitter
//

import SwiftUI
import Combine

/// Menu bar labels are rendered as a static image, so SwiftUI animations
/// don't play there. The globe is spun by swapping pre-rendered frames.
struct MenuBarIcon: View {
    var isRunning: Bool
    @State private var frame = 0

    private static let frames: [NSImage] = {
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        guard let base = NSImage(systemSymbolName: "network", accessibilityDescription: "VPN Splitter")?
            .withSymbolConfiguration(config) else { return [] }
        return stride(from: 0, to: 360, by: 15).map { rotated(base, by: -Double($0)) }
    }()

    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let image = Self.frames[safe: isRunning ? frame : 0] {
                Image(nsImage: image)
            } else {
                Image(systemName: "network")
            }
        }
        .onReceive(timer) { _ in
            guard isRunning, !Self.frames.isEmpty else { return }
            frame = (frame + 1) % Self.frames.count
        }
        .onChange(of: isRunning) { if !isRunning { frame = 0 } }
    }

    private static func rotated(_ image: NSImage, by degrees: Double) -> NSImage {
        let size = image.size
        let result = NSImage(size: size, flipped: false) { rect in
            let transform = NSAffineTransform()
            transform.translateX(by: size.width / 2, yBy: size.height / 2)
            transform.rotate(byDegrees: degrees)
            transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
            transform.concat()
            image.draw(in: rect)
            return true
        }
        result.isTemplate = true
        return result
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
