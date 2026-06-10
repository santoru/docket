// SwipeableTaskRow.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Wraps a TaskRowView with swipe-to-complete/delete gestures and a
/// press-and-hold drag-to-reorder gesture.
///
/// Reorder model: holding the row still for ~0.3s "lifts" it (the parent
/// `TaskListView` applies the visual offset/scale and runs the reorder math);
/// moving the cursor before that threshold instead triggers the horizontal
/// swipe. Quick taps open the task. The `LongPressGesture`'s small
/// `maximumDistance` means a fast horizontal flick cancels the long-press and
/// lets the swipe win, so the two never fight.
struct SwipeableTaskRow: View {
    let item: TodoItem
    var reorderEnabled: Bool = false
    var isLifted: Bool = false
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    var onReorderBegin: () -> Void = {}
    var onReorderChange: (CGFloat) -> Void = { _ in }
    var onReorderEnd: () -> Void = {}

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Swipe background — only visible during an active swipe.
            if offset > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green)
                    .overlay(alignment: .leading) {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.leading, 16)
                    }
            } else if offset < 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .overlay(alignment: .trailing) {
                        Label("Delete", systemImage: "trash.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.trailing, 16)
                    }
            }

            TaskRowView(item: item, onComplete: onComplete)
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
                .gesture(isLifted ? nil : swipeGesture)
        }
        // Reorder takes priority when enabled; disabled (so taps/swipes pass to
        // the inner view) otherwise.
        .highPriorityGesture(reorderGesture, including: reorderEnabled ? .all : .subviews)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    offset = value.translation.width
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 80
                if value.translation.width > threshold {
                    withAnimation(.spring(duration: 0.3)) { offset = 400 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onComplete() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { offset = 0 }
                } else if value.translation.width < -threshold {
                    withAnimation(.spring(duration: 0.3)) { offset = -400 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDelete() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { offset = 0 }
                } else {
                    withAnimation(.spring(duration: 0.25)) { offset = 0 }
                }
            }
    }

    // MARK: - Reorder Gesture (long-press → drag)

    private var reorderGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3, maximumDistance: 10)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(TaskListCoordinateSpace.name)))
            .onChanged { value in
                switch value {
                case .first(true):
                    onReorderBegin()
                case .second(true, let drag?):
                    onReorderChange(drag.translation.height)
                default:
                    break
                }
            }
            .onEnded { _ in onReorderEnd() }
    }
}
