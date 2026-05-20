// ConfettiView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A single confetti particle.
private struct Piece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let drift: CGFloat
}

/// Overlay that bursts confetti downward from the top when `isActive` becomes true.
struct ConfettiOverlay: View {
    @Binding var isActive: Bool
    @State private var pieces: [Piece] = []
    @State private var animate = false

    private static let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 0.6)
                        .rotationEffect(.degrees(animate ? p.rotation + 360 : p.rotation))
                        .offset(
                            x: (geo.size.width / 2) + p.x + (animate ? p.drift : 0),
                            y: animate ? geo.size.height * 0.6 : 40
                        )
                        .opacity(animate ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { fire() }
        }
    }

    private func fire() {
        pieces = (0..<25).map { _ in
            Piece(
                x: .random(in: -120...120),
                color: Self.colors.randomElement()!,
                size: .random(in: 4...7),
                rotation: .random(in: 0...360),
                drift: .random(in: -40...40)
            )
        }
        animate = false
        withAnimation(.easeOut(duration: 1.0)) { animate = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            pieces = []
            animate = false
            isActive = false
        }
    }
}
