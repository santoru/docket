// TaskRowView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A single task card showing title, due date, priority bar, and complete button.
struct TaskRowView: View {
    let item: TodoItem
    let onComplete: () -> Void

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("useGlass") private var useGlass = true
    @State private var isHovered = false

    private var priorityColor: Color {
        switch item.priority {
        case .high: Color(red: 0.95, green: 0.50, blue: 0.55)
        case .medium: Color(red: 0.95, green: 0.75, blue: 0.40)
        case .low: Color(red: 0.45, green: 0.72, blue: 0.95)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor.gradient)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let due = item.dueDate {
                        Image(systemName: "clock").font(.caption2)
                        Text(DueDateFormatter.format(due)).font(.caption)
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                    }
                    if !item.labelIds.isEmpty {
                        ForEach(Store.shared.labels.filter { item.labelIds.contains($0.id) }) { label in
                            Text(label.name)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(label.color.opacity(0.15)))
                                .foregroundStyle(label.color)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            if item.recurrence != nil {
                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(item.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(useGlass ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(ThemeManager.resolvedCardBackground(themeRaw: themeRaw)))
                .shadow(color: .black.opacity(useGlass ? 0 : (isHovered ? 0.08 : 0.04)), radius: isHovered ? 4 : 2, y: isHovered ? 2 : 1)
        )
        .overlay(useGlass ? nil : RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 0.5))
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.priority.displayName) priority\(item.dueDate != nil ? ", due \(DueDateFormatter.format(item.dueDate!))" : "")")
    }
}
