// IconPickerButton.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Compact button showing the current icon, opens a popover that hosts
/// `IconPickerGrid`. The icon equivalent of `ColorSwatchButton`, with the
/// same popover styling so the two pickers feel like one control surface.
struct IconPickerButton: View {
    @Binding var icon: String
    /// Accent color used for the icon glyph and the picker grid's tint.
    /// Pass the surrounding label/list color so the button visually
    /// belongs to its row.
    var tint: Color = .accentColor

    /// Optional title shown in the popover header (typically the label name).
    var popoverTitle: String? = nil

    /// Edge the popover anchors to. Defaults to leading.
    var popoverEdge: Edge = .leading

    /// Visual size of the button itself.
    var size: CGFloat = 22

    @State private var showPicker = false

    var body: some View {
        Button { showPicker.toggle() } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 0.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(L10n.icon)
        .accessibilityLabel(Text(L10n.icon))
        .popover(isPresented: $showPicker, arrowEdge: popoverEdge) {
            VStack(alignment: .leading, spacing: 10) {
                if let popoverTitle, !popoverTitle.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(tint)
                            .frame(width: 14, height: 14)
                        Text(popoverTitle).font(.subheadline.weight(.semibold))
                    }
                }
                IconPickerGrid(icon: $icon, tint: tint)
            }
            .padding(12)
            .frame(width: 240)
        }
    }
}
