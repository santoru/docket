// RowActionButton.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Small icon-only button suited for inline row actions (edit / delete /
/// duplicate / etc.) following macOS HIG conventions:
///
/// * 24pt circular hit-target with a subtle hover background.
/// * Press state darkens the background slightly.
/// * `destructive` variant tints red on hover and press.
/// * Always carries a `.help()` tooltip and a matching VoiceOver label —
///   icon-only buttons MUST be self-describing for accessibility.
struct RowActionButton: View {
    let systemImage: String
    let label: String
    var destructive: Bool = false
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(background)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .animation(.easeOut(duration: 0.12), value: hovered)
        }
        .buttonStyle(PressableScaleStyle())
        .onHover { hovered = $0 }
        .help(label)
        .accessibilityLabel(Text(label))
    }

    private var foreground: Color {
        if destructive {
            return hovered ? .red : .secondary
        }
        return hovered ? .primary : .secondary
    }

    private var background: Color {
        guard hovered else { return .clear }
        return destructive ? Color.red.opacity(0.14) : Color.primary.opacity(0.08)
    }
}

/// Adds a small press-down scale to a button without changing its layout.
/// Pairs cleanly with custom `.background(...)` decorations.
private struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
