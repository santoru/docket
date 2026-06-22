// IconPickerGrid.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Grid picker for label icons. Mirrors `ColorPickerGrid` so the two pickers
/// feel like one product:
///
/// * 5 columns × 3 rows = 15 SF Symbols (the preset set on `TaskLabel`).
/// * Selected cell uses a solid tint fill with a contrasting glyph; unselected
///   cells use a low-opacity tint fill with the glyph in the tint color.
/// * Tint follows the surrounding label color so the picker visually
///   "belongs" to the label being edited.
struct IconPickerGrid: View {
    @Binding var icon: String
    var tint: Color = .accentColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    private let cellSize: CGFloat = 32

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(TaskLabel.presetIcons, id: \.self) { name in
                cell(for: name)
            }
        }
    }

    @ViewBuilder
    private func cell(for name: String) -> some View {
        let isSelected = name == icon
        Button { icon = name } label: {
            Image(systemName: name)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
                .frame(width: cellSize, height: cellSize)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? tint : tint.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(tint.opacity(isSelected ? 0 : 0.18), lineWidth: 0.5)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .help(IconPalette.displayName(name))
        .accessibilityLabel(Text(IconPalette.displayName(name)))
    }
}
