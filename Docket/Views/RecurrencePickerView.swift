// RecurrencePickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Picker for task recurrence (repeat frequency and interval).
struct RecurrencePickerView: View {
    @Binding var hasRecurrence: Bool
    @Binding var frequency: Frequency
    @Binding var interval: Int

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThemedToggle(label: "Repeat", isOn: $hasRecurrence, animated: true)
            if hasRecurrence {
                HStack {
                    Text("Every").font(.body)
                    Spacer()
                    Menu {
                        ForEach(1...10, id: \.self) { n in
                            Button("\(n)") { interval = n }
                        }
                    } label: {
                        Text("\(interval)")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)

                    Menu {
                        ForEach(Frequency.allCases) { f in
                            Button(f.displayName) { frequency = f }
                        }
                    } label: {
                        Text(interval == 1 ? frequency.unit : "\(frequency.unit)s")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
