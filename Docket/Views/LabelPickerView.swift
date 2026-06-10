// LabelPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Multi-select label picker showing colored pills.
struct LabelPickerView: View {
    @Binding var selectedIds: [UUID]
    var store = Store.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.labels).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            if store.labelsForActiveList.isEmpty {
                Text(L10n.noLabels).font(.subheadline).foregroundStyle(.tertiary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(store.labelsForActiveList) { label in
                        let isSelected = selectedIds.contains(label.id)
                        Button {
                            if isSelected { selectedIds.removeAll { $0 == label.id } }
                            else { selectedIds.append(label.id) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: label.icon)
                                    .font(.system(size: 11))
                                Text(label.name)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(isSelected ? label.color.opacity(0.2) : Color.gray.opacity(0.1)))
                            .overlay(Capsule().stroke(isSelected ? label.color : Color.gray.opacity(0.3), lineWidth: 1))
                            .foregroundStyle(isSelected ? label.color : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// Simple flow layout for wrapping pills.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (origins: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (origins, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
