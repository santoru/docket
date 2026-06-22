// PressableScaleStyle.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Adds a small press-down scale to a button without changing its layout.
/// Pairs cleanly with custom `.background(...)` decorations and works well
/// alongside hover-driven scale modifiers (the two scales multiply).
struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
