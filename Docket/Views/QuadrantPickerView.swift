// QuadrantPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// 2×2 grid picker for assigning a task to an Eisenhower quadrant.
struct QuadrantPickerView: View {
    @Binding var quadrant: Quadrant?

    @AppStorage("matrixDoFirstColor") private var doFirstColor = "#EF4444"
    @AppStorage("matrixScheduleColor") private var scheduleColor = "#3B82F6"
    @AppStorage("matrixDelegateColor") private var delegateColor = "#F59E0B"
    @AppStorage("matrixEliminateColor") private var eliminateColor = "#9CA3AF"
    @AppStorage("matrixDoFirstLabel") private var doFirstLabel = "Do First"
    @AppStorage("matrixScheduleLabel") private var scheduleLabel = "Schedule"
    @AppStorage("matrixDelegateLabel") private var delegateLabel = "Delegate"
    @AppStorage("matrixEliminateLabel") private var eliminateLabel = "Eliminate"

    private func color(for q: Quadrant) -> Color {
        switch q {
        case .doFirst: Color(hex: doFirstColor)
        case .schedule: Color(hex: scheduleColor)
        case .delegate: Color(hex: delegateColor)
        case .eliminate: Color(hex: eliminateColor)
        }
    }

    private func label(for q: Quadrant) -> String {
        switch q {
        case .doFirst: doFirstLabel
        case .schedule: scheduleLabel
        case .delegate: delegateLabel
        case .eliminate: eliminateLabel
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.matrix).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(Quadrant.allCases) { q in
                    let c = color(for: q)
                    Button { quadrant = quadrant == q ? nil : q } label: {
                        HStack(spacing: 4) {
                            Image(systemName: q.icon).font(.system(size: 10))
                            Text(label(for: q)).font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(quadrant == q ? c.opacity(0.2) : Color.gray.opacity(0.1)))
                        .overlay(Capsule().stroke(quadrant == q ? c : Color.gray.opacity(0.3), lineWidth: 1))
                        .foregroundStyle(quadrant == q ? c : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
