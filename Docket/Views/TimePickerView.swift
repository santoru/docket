// TimePickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A themed hour:minute picker using dropdown menus.
struct TimePickerView: View {
    @Binding var date: Date

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }
    private let calendar = Calendar.current
    private var hour: Int { calendar.component(.hour, from: date) }
    private var minute: Int { calendar.component(.minute, from: date) }

    var body: some View {
        HStack(spacing: 12) {
            Text("Time").font(.body.weight(.medium))
            Spacer()
            HStack(spacing: 4) {
                timeMenu(value: hour, format: "%02d") { setHour($0) } items: {
                    ForEach(0..<24, id: \.self) { h in
                        Button(String(format: "%02d", h)) { setHour(h) }
                    }
                }
                Text(":").font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                timeMenu(value: minute, format: "%02d") { setMinute($0) } items: {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                        Button(String(format: "%02d", m)) { setMinute(m) }
                    }
                }
            }
        }
    }

    private func timeMenu<Items: View>(
        value: Int, format: String,
        action: @escaping (Int) -> Void,
        @ViewBuilder items: () -> Items
    ) -> some View {
        Menu {
            items()
        } label: {
            Text(String(format: format, value))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
    }

    private func setHour(_ h: Int) {
        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        comps.hour = h
        date = calendar.date(from: comps) ?? date
    }

    private func setMinute(_ m: Int) {
        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        comps.minute = m
        date = calendar.date(from: comps) ?? date
    }
}
