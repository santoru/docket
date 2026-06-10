// PriorityPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A themed priority picker with colored pill buttons.
struct PriorityPickerView: View {
    @Binding var priority: Priority

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Priority").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(Priority.allCases) { p in
                    Button { withAnimation(.easeInOut(duration: 0.15)) { priority = p } } label: {
                        Text(p.displayName)
                            .font(.subheadline.weight(priority == p ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(priority == p ? p.color : .clear)
                            )
                            .foregroundStyle(priority == p ? .white : .secondary)
                            .overlay(Capsule().stroke(priority == p ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
