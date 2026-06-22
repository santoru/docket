// ColorPickerGrid.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit

/// Reusable color picker showing the shared `ColorPalette` as a 5×4 grid of
/// rounded swatches, plus a "Custom…" row that opens the native macOS color
/// panel for users who want a hex outside the palette.
///
/// Used by both the Label editor and the List color picker so they feel like
/// the same control.
struct ColorPickerGrid: View {
    /// Two-way binding to the hex string the caller persists.
    @Binding var hex: String

    /// Called when the picker mutates `hex` (preset tap or custom-color
    /// change). Useful for committing to disk if the caller doesn't already
    /// observe the binding.
    var onChange: ((String) -> Void)? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    private let swatchSize: CGFloat = 28

    /// Mirror state for the native ColorPicker. We keep it in sync with the
    /// hex binding, but only push back to `hex` when the user actually edits
    /// it (otherwise the deterministic legacy fallback would be "promoted" to
    /// a stored value just by opening the editor).
    @State private var customColor: Color = .clear
    @State private var customColorPrimed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ColorPalette.presets, id: \.hex) { preset in
                    swatch(for: preset)
                }
            }

            customRow
        }
        .onAppear {
            // Prime the ColorPicker binding to the current selection without
            // triggering the "user changed it" path.
            customColor = Color(hex: hex)
            customColorPrimed = true
        }
        .onChange(of: customColor) { _, newValue in
            // Ignore the priming write and any spurious .clear values.
            guard customColorPrimed,
                  let newHex = newValue.toHex(),
                  newHex.uppercased() != hex.uppercased() else { return }
            hex = newHex
            onChange?(newHex)
        }
    }

    // MARK: - Swatch

    @ViewBuilder
    private func swatch(for preset: (name: String, hex: String)) -> some View {
        let color = Color(hex: preset.hex)
        let isSelected = preset.hex.uppercased() == hex.uppercased()
        Button {
            hex = preset.hex
            customColor = color // keep the system picker aligned
            onChange?(preset.hex)
        } label: {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)
                .frame(width: swatchSize, height: swatchSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.95 : 0), lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(color.opacity(isSelected ? 0.6 : 0.15),
                                lineWidth: isSelected ? 2 : 0.5)
                        .scaleEffect(isSelected ? 1.18 : 1.0)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .help(preset.name)
        .accessibilityLabel(Text(preset.name))
    }

    // MARK: - Custom row

    private var customRow: some View {
        HStack(spacing: 8) {
            // Decorative conic-gradient hint.
            Circle()
                .fill(AngularGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                    center: .center
                ))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white, lineWidth: 1))

            Text(L10n.colorCustom)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            // Native macOS color well. Its swatch is the click target and
            // opens NSColorPanel.
            ColorPicker("", selection: $customColor, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Color → hex
//
// `Color.toHex()` lives in Models/ColorPalette.swift so it is also reachable
// from the test target (which only compiles Models).

