// MatrixLayout.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import CoreGraphics

/// Pure geometry for the Eisenhower Matrix: pill sizing and the anti-collision
/// resolver. Extracted from `MatrixView` so the algorithm can be unit-tested
/// without instantiating any SwiftUI view.
enum MatrixLayout {
    /// The expected on-screen size of a task pill, given the current settings
    /// and the available quadrant width. Both the view and the resolver use
    /// these dimensions so positioning math stays in sync with what's drawn.
    static func pillSize(maxChars: Int, lineCount: Int, in containerWidth: CGFloat) -> CGSize {
        let rawTextWidth = max(36, CGFloat(maxChars) * 5.6)
        let textCap = max(20, containerWidth - 26 - 8)
        let textWidth = min(rawTextWidth, textCap)
        let lineHeight: CGFloat = 13
        return CGSize(
            width: textWidth + 26,                       // text + dot(5) + spacing(5) + 2*hPad(8)
            height: CGFloat(lineCount) * lineHeight + 9  // text height + 2*vPad(4.5)
        )
    }

    /// Compute on-screen pill centers using rectangle-overlap detection. Pills
    /// are spiralled outward by small, deterministic increments until their
    /// bounding box no longer intersects any previously placed pill. Bounds are
    /// derived from the actual pill size so no pill overflows the quadrant.
    ///
    /// `seeds` are fractional positions in `0...1` (x, y) within the box; the
    /// caller maps a task's stored `matrixX`/`matrixY` (defaulting to 0.5).
    static func resolvePositions(seeds: [CGPoint], in size: CGSize, maxChars: Int, lineCount: Int) -> [CGPoint] {
        guard size.width > 0, size.height > 0 else {
            return Array(repeating: .zero, count: seeds.count)
        }

        let pill = pillSize(maxChars: maxChars, lineCount: lineCount, in: size.width)
        let pad: CGFloat = 4
        let xMin = pill.width / 2 + pad
        let xMax = max(xMin + 1, size.width - pill.width / 2 - pad)
        let yMin = pill.height / 2 + pad
        let yMax = max(yMin + 1, size.height - pill.height / 2 - pad)

        // Inflate rects by 2pt before intersection-testing so pills never visually touch.
        let inflate: CGFloat = 2

        func rectAt(_ p: CGPoint) -> CGRect {
            CGRect(
                x: p.x - pill.width / 2 - inflate,
                y: p.y - pill.height / 2 - inflate,
                width: pill.width + inflate * 2,
                height: pill.height + inflate * 2
            )
        }

        var placed: [CGRect] = []
        var positions: [CGPoint] = []
        positions.reserveCapacity(seeds.count)

        for seed in seeds {
            let baseX = seed.x * size.width
            let baseY = seed.y * size.height
            var p = clampPoint(CGPoint(x: baseX, y: baseY),
                               xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)

            var attempt = 0
            while attempt < 32 && placed.contains(where: { rectAt(p).intersects($0) }) {
                attempt += 1
                let angle = Double(attempt) * 1.92
                let radius = 14.0 + Double(attempt) * 5.0
                p = clampPoint(
                    CGPoint(x: baseX + CGFloat(cos(angle) * radius),
                            y: baseY + CGFloat(sin(angle) * radius)),
                    xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax
                )
            }

            placed.append(rectAt(p))
            positions.append(p)
        }
        return positions
    }

    static func clampPoint(_ p: CGPoint, xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(p.x, xMin), xMax),
            y: min(max(p.y, yMin), yMax)
        )
    }
}
