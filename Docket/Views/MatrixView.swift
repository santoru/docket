// MatrixView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Eisenhower Matrix view with free-positioned draggable tasks.
struct MatrixView: View {
    @Binding var path: [NavDestination]
    var store = Store.shared

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        VStack(spacing: 0) {
            header
            matrixGrid
            unassignedSection
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.quaternary.opacity(0.5)))
            }.buttonStyle(.plain)
            Spacer()
            Text("Eisenhower Matrix").font(.headline)
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Matrix Grid

    private var matrixGrid: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                quadrantBox(.doFirst)
                quadrantBox(.schedule)
            }
            HStack(spacing: 2) {
                quadrantBox(.delegate)
                quadrantBox(.eliminate)
            }
        }
        .padding(.horizontal, 8)
    }

    private func quadrantBox(_ quadrant: Quadrant) -> some View {
        let tasks = store.activeTasks.filter { $0.quadrant == quadrant }

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(quadrant.color.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(quadrant.color.opacity(0.2), lineWidth: 0.5))

                // Quadrant label
                Text(quadrant.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(quadrant.color)
                    .padding(4)

                // Tasks positioned freely
                ForEach(tasks) { item in
                    TaskDot(item: item, quadrant: quadrant, bounds: geo.size, onTap: {
                        path.append(.detail(item))
                    })
                }
            }
        }
        .aspectRatio(1.3, contentMode: .fit)
    }

    // MARK: - Unassigned

    private var unassignedSection: some View {
        let unassigned = store.activeTasks.filter { $0.quadrant == nil }
        return Group {
            if !unassigned.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unassigned")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(unassigned) { item in
                                Button { path.append(.detail(item)) } label: {
                                    Text(item.title)
                                        .font(.system(size: 10))
                                        .lineLimit(1)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(.quaternary.opacity(0.5)))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    ForEach(Quadrant.allCases) { q in
                                        Button {
                                            if let i = store.items.firstIndex(where: { $0.id == item.id }) {
                                                store.items[i].quadrant = q
                                                store.items[i].matrixX = 0.5
                                                store.items[i].matrixY = 0.5
                                            }
                                        } label: {
                                            Label(q.name, systemImage: q.icon)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Task Dot (draggable within quadrant)

struct TaskDot: View {
    let item: TodoItem
    let quadrant: Quadrant
    let bounds: CGSize
    let onTap: () -> Void

    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Text(String(item.title.prefix(12)))
            .font(.system(size: 9, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(quadrant.color.opacity(0.15)))
            .overlay(Capsule().stroke(quadrant.color.opacity(0.3), lineWidth: 0.5))
            .foregroundStyle(quadrant.color)
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let newX = clamp((position.x + value.translation.width) / bounds.width, 0.05, 0.95)
                        let newY = clamp((position.y + value.translation.height) / bounds.height, 0.1, 0.9)
                        dragOffset = .zero
                        position = CGPoint(x: newX * bounds.width, y: newY * bounds.height)

                        // Persist position
                        if let i = Store.shared.items.firstIndex(where: { $0.id == item.id }) {
                            Store.shared.items[i].matrixX = newX
                            Store.shared.items[i].matrixY = newY
                        }
                    }
            )
            .onTapGesture { onTap() }
            .onAppear {
                let x = item.matrixX ?? Double.random(in: 0.2...0.8)
                let y = item.matrixY ?? Double.random(in: 0.2...0.8)
                position = CGPoint(x: x * bounds.width, y: y * bounds.height)
            }
    }

    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}
