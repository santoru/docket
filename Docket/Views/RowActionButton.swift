// RowActionButton.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Compact icon-only button used for inline row actions (edit / delete /
/// duplicate / etc.). Visual style mirrors Apple's "tinted compact action
/// button" pattern from Mail, Reminders, and Photos:
///
/// * Circular fill in the action's tint at low opacity, deepening on hover.
/// * SF Symbol rendered semibold with hierarchical mode for subtle depth.
/// * Hairline border at rest gives the button a crafted edge that fades on hover.
/// * Hover scales up with a spring; press scales down, so the affordance
///   feels responsive without competing with the row content.
/// * `destructive` variant locks to system red regardless of the surrounding
///   tint; non-destructive uses the environment `.tint` (or `.accentColor`).
/// * Always carries a `.help()` tooltip and matching VoiceOver label —
///   icon-only buttons MUST be self-describing for accessibility.
struct RowActionButton: View {
    let systemImage: String
    let label: String
    /// Accent used when not destructive. Defaults to the system accent so the
    /// button looks correct out of the box; the SettingsView passes the
    /// resolved theme accent so edit buttons match the app's theme.
    var tint: Color = .accentColor
    var destructive: Bool = false
    let action: () -> Void

    @State private var hovered = false

    private let size: CGFloat = 26

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconStyle)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(backgroundStyle)
                )
                .overlay(
                    Circle()
                        .strokeBorder(borderStyle, lineWidth: 0.5)
                )
                .scaleEffect(hovered ? 1.06 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.72), value: hovered)
                .contentShape(Circle())
        }
        .buttonStyle(PressableScaleStyle())
        .onHover { hovered = $0 }
        .help(label)
        .accessibilityLabel(Text(label))
    }

    // MARK: - Styling

    /// Effective accent — destructive trumps the configured tint.
    private var effectiveTint: Color { destructive ? .red : tint }

    private var iconStyle: AnyShapeStyle {
        AnyShapeStyle(effectiveTint.opacity(hovered ? 1.0 : 0.85))
    }

    private var backgroundStyle: AnyShapeStyle {
        AnyShapeStyle(effectiveTint.opacity(hovered ? 0.18 : 0.10))
    }

    private var borderStyle: AnyShapeStyle {
        AnyShapeStyle(effectiveTint.opacity(hovered ? 0 : 0.18))
    }
}
