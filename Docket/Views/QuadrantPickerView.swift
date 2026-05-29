// QuadrantPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// 2×2 grid picker for assigning a task to an Eisenhower quadrant.
struct QuadrantPickerView: View {
    @Binding var quadrant: Quadrant?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Matrix").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(Quadrant.allCases) { q in
                    Button { quadrant = quadrant == q ? nil : q } label: {
                        HStack(spacing: 4) {
                            Image(systemName: q.icon).font(.system(size: 10))
                            Text(q.name).font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(quadrant == q ? q.color.opacity(0.2) : Color.gray.opacity(0.1)))
                        .overlay(Capsule().stroke(quadrant == q ? q.color : Color.gray.opacity(0.3), lineWidth: 1))
                        .foregroundStyle(quadrant == q ? q.color : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
