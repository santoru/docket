// SwipeableTaskRow.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Wraps a TaskRowView with swipe-to-complete/delete gestures and reorder controls.
struct SwipeableTaskRow: View {
    let item: TodoItem
    let editMode: Bool
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Swipe background — only visible during active swipe
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

            // Foreground content
            HStack(spacing: 0) {
                if editMode {
                    reorderButtons
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                TaskRowView(item: item, onComplete: onComplete)
            }
            .offset(x: offset)
            .contentShape(Rectangle())
            .onTapGesture { if !editMode { onTap() } }
            .gesture(editMode ? nil : swipeGesture)
        }
    }

    // MARK: - Reorder Buttons

    private var reorderButtons: some View {
        VStack(spacing: 4) {
            Button { onMoveUp?() } label: {
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .frame(width: 22, height: 18)
                    .foregroundStyle(onMoveUp == nil ? .quaternary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(onMoveUp == nil)

            Button { onMoveDown?() } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .frame(width: 22, height: 18)
                    .foregroundStyle(onMoveDown == nil ? .quaternary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(onMoveDown == nil)
        }
        .padding(.trailing, 4)
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
}
