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
    var onReorderChange: (_ translationY: CGFloat) -> Void = { _ in }
    var onReorderEnd: () -> Void = {}

    @State private var offset: CGFloat = 0
    /// Auto-resets to false whenever the reorder gesture ends or is cancelled —
    /// our reliable signal to clean up (the sequenced gesture's own .onEnded does
    /// NOT fire when the press is released without a drag, which left the card
    /// stuck in the lifted state).
    @GestureState private var reorderActive = false
    /// Becomes true only once the finger moves after the hold — so the lift/grow
    /// is tied to actual dragging, not merely holding the press.
    @State private var reorderBegun = false
    /// Visual "grab" feedback during a held press. Driven by a manual timer so
    /// it's independent of the gesture's own (unreliable) recognition timing,
    /// and purely cosmetic so it never affects tap/swipe/drag behavior.
    @State private var pressed = false
    @State private var pressTimer: Timer?

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
                .scaleEffect(pressed && !isLifted ? 1.03 : 1.0)
                .offset(x: offset)
                .contentShape(Rectangle())
                .gesture(isLifted ? nil : swipeGesture)
        }
        // A quick click opens the task — high priority so it wins over the
        // long-press for fast clicks.
        .highPriorityGesture(TapGesture().onEnded { onTap() })
        // Simultaneous so it doesn't steal the event stream from the tap/swipe.
        // The 0.5s long-press time-gate separates a reorder (held) from a quick
        // tap or a fast horizontal swipe.
        .simultaneousGesture(reorderGesture, including: reorderEnabled ? .all : .subviews)
        .onChange(of: reorderActive) { _, active in
            if active {
                startPressFeedback()
            } else {
                // Gesture ended/cancelled in any way → ensure cleanup runs even if
                // the sequenced gesture's .onEnded didn't fire.
                cancelPressFeedback()
                reorderBegun = false
                onReorderEnd()
            }
        }
    }

    // MARK: - Press Feedback

    /// After a short hold, grow the row in place to signal it's grabbed. The
    /// timer is cancelled by any release/move that ends the press first (a quick
    /// click or a swipe), so those never grow. Uses .common run-loop mode so it
    /// fires while the mouse button is held (event tracking).
    private func startPressFeedback() {
        pressTimer?.invalidate()
        let t = Timer(timeInterval: 0.18, repeats: false) { _ in
            withAnimation(.spring(duration: 0.22, bounce: 0.35)) { pressed = true }
        }
        RunLoop.main.add(t, forMode: .common)
        pressTimer = t
    }

    private func cancelPressFeedback() {
        pressTimer?.invalidate()
        pressTimer = nil
        if pressed { withAnimation(.easeOut(duration: 0.15)) { pressed = false } }
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
        LongPressGesture(minimumDuration: 0.18, maximumDistance: 10)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .updating($reorderActive) { _, state, _ in state = true }
            .onChanged { value in
                // Lift only once the finger actually MOVES after the hold, so a
                // press-and-release (even a slow one) stays a click and never grows.
                if case .second(true, let drag?) = value {
                    if !reorderBegun {
                        guard abs(drag.translation.height) > 4 || abs(drag.translation.width) > 4 else { return }
                        reorderBegun = true
                        onReorderBegin()
                    }
                    onReorderChange(drag.translation.height)
                }
            }
            .onEnded { _ in
                reorderBegun = false
                onReorderEnd()
            }
    }
}
