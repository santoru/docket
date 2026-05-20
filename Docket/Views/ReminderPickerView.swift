// ReminderPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A themed reminder offset picker using a dropdown menu, matching TimePickerView style.
struct ReminderPickerView: View {
    @Binding var offset: ReminderOffset

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        HStack(spacing: 12) {
            Text("Remind me").font(.body.weight(.medium))
            Spacer()
            Menu {
                ForEach(ReminderOffset.allCases) { r in
                    Button(r.displayName) { offset = r }
                }
            } label: {
                Text(offset.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
        }
    }
}
