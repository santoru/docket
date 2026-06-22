// ColorSwatchButton.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Compact color swatch that opens a popover hosting `ColorPickerGrid`.
///
/// Unifies every "pick a color" affordance in Settings (lists, matrix
/// quadrants, anywhere else that grows one in the future) so they share
/// the same visual language and underlying palette.
struct ColorSwatchButton: View {
    /// Two-way binding to the hex string.
    @Binding var hex: String

    /// Optional title shown above the picker inside the popover (e.g. the
    /// list or quadrant name). Set nil to omit the header.
    var popoverTitle: String? = nil

    /// Visual size of the swatch button itself.
    var size: CGFloat = 14

    /// Optional ring around the swatch — used by the lists section to mark
    /// the active list. Pass nil to omit.
    var ringColor: Color? = nil

    /// Edge the popover anchors to. Defaults to leading because most call
    /// sites place the swatch on the left of a row.
    var popoverEdge: Edge = .leading

    @State private var showPicker = false

    var body: some View {
        Button { showPicker.toggle() } label: {
            swatch(size: size, ringColor: ringColor)
        }
        .buttonStyle(.plain)
        .help(L10n.color)
        .accessibilityLabel(Text(L10n.color))
        .popover(isPresented: $showPicker, arrowEdge: popoverEdge) {
            VStack(alignment: .leading, spacing: 10) {
                if let popoverTitle, !popoverTitle.isEmpty {
                    HStack(spacing: 8) {
                        swatch(size: 14, ringColor: nil)
                        Text(popoverTitle).font(.subheadline.weight(.semibold))
                    }
                }
                ColorPickerGrid(hex: $hex)
            }
            .padding(12)
            .frame(width: 240)
        }
    }

    @ViewBuilder
    private func swatch(size: CGFloat, ringColor: Color?) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        shape
            .fill(Color(hex: hex))
            .frame(width: size, height: size)
            .overlay(
                shape.stroke(ringColor ?? .clear, lineWidth: ringColor == nil ? 0 : 1.5)
                    .padding(-2)
            )
            .overlay(
                shape.stroke(.black.opacity(0.08), lineWidth: 0.5)
            )
    }
}
