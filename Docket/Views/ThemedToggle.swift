// ThemedToggle.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A toggle styled as a label + accent-colored pill switch.
struct ThemedToggle: View {
    let label: String
    @Binding var isOn: Bool
    var animated: Bool = false

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Button {
                if animated {
                    withAnimation(.easeInOut(duration: 0.2)) { isOn.toggle() }
                } else {
                    isOn.toggle()
                }
            } label: {
                Capsule()
                    .fill(isOn ? accent : Color.gray.opacity(0.3))
                    .frame(width: 38, height: 22)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .padding(2)
                            .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                    }
                    .animation(.easeInOut(duration: 0.15), value: isOn)
            }
            .buttonStyle(.plain)
        }
    }
}
