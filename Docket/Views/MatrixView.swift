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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { path.removeLast() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.quaternary.opacity(0.5)))
                    }.buttonStyle(.plain)
                    Spacer()
                    Text("Matrix").font(.headline)
                    Spacer()
                    Button { path.removeLast() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.quaternary.opacity(0.5)))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Axis labels
            HStack(spacing: 0) {
                Color.clear.frame(width: 14) // match Y-axis width
                HStack(spacing: 3) {
                    Text("URGENT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                    Text("NOT URGENT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            // Matrix grid
            HStack(spacing: 0) {
                // Y-axis labels aligned with rows
                VStack(spacing: 3) {
                    VStack(spacing: 1) {
                        ForEach(Array("IMPORTANT"), id: \.self) { c in
                            Text(String(c)).font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 140)
                    VStack(spacing: 1) {
                        ForEach(Array("NOT IMP."), id: \.self) { c in
                            Text(String(c)).font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 140)
                }
                .frame(width: 14)

                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        quadrantBox(.doFirst)
                        quadrantBox(.schedule)
                    }
                    HStack(spacing: 3) {
                        quadrantBox(.delegate)
                        quadrantBox(.eliminate)
                    }
                }
            }
            .padding(.horizontal, 8)

            unassignedSection
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Quadrant Box

    private func quadrantBox(_ quadrant: Quadrant) -> some View {
        let tasks = store.activeTasks.filter { $0.quadrant == quadrant }

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Gradient background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [quadrant.color.opacity(0.15), quadrant.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(quadrant.color.opacity(0.3), lineWidth: 1)
                    )

                // Label with icon
                HStack(spacing: 3) {
                    Image(systemName: quadrant.icon)
                        .font(.system(size: 8))
                    Text(quadrant.name)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(quadrant.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)

                // Task count badge
                if !tasks.isEmpty {
                    Text("\(tasks.count)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(quadrant.color))
                        .position(x: geo.size.width - 14, y: 14)
                }

                // Tasks
                ForEach(tasks) { item in
                    TaskDot(item: item, quadrant: quadrant, bounds: geo.size, onTap: {
                        path.append(.detail(item))
                    })
                }
            }
            .dropDestination(for: String.self) { items, _ in
                for idString in items {
                    if let uuid = UUID(uuidString: idString),
                       let i = store.items.firstIndex(where: { $0.id == uuid }) {
                        store.items[i].quadrant = quadrant
                        store.items[i].matrixX = 0.5
                        store.items[i].matrixY = 0.5
                    }
                }
                return true
            }
        }
        .frame(height: 140)
    }

    // MARK: - Unassigned

    private var unassignedSection: some View {
        let unassigned = store.activeTasks.filter { $0.quadrant == nil }
        return Group {
            if !unassigned.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Unassigned")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(unassigned.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(unassigned) { item in
                                Button { path.append(.detail(item)) } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(priorityColor(item.priority))
                                            .frame(width: 6, height: 6)
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.regularMaterial)
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 0.5))
                                    .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .draggable(item.id.uuidString)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high: Color(red: 0.95, green: 0.50, blue: 0.55)
        case .medium: Color(red: 0.95, green: 0.75, blue: 0.40)
        case .low: Color(red: 0.45, green: 0.72, blue: 0.95)
        }
    }
}

// MARK: - Task Dot

struct TaskDot: View {
    let item: TodoItem
    let quadrant: Quadrant
    let bounds: CGSize
    let onTap: () -> Void

    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(quadrant.color)
                .frame(width: 5, height: 5)
            Text(String(item.title.prefix(14)))
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: quadrant.color.opacity(isDragging ? 0.3 : 0.1), radius: isDragging ? 6 : 2, y: isDragging ? 3 : 1)
        )
        .overlay(Capsule().stroke(quadrant.color.opacity(isDragging ? 0.5 : 0.2), lineWidth: 0.5))
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .draggable(item.id.uuidString)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    let newX = clamp((position.x + value.translation.width) / bounds.width, 0.08, 0.92)
                    let newY = clamp((position.y + value.translation.height) / bounds.height, 0.15, 0.9)
                    dragOffset = .zero
                    withAnimation(.spring(duration: 0.25)) {
                        position = CGPoint(x: newX * bounds.width, y: newY * bounds.height)
                    }
                    if let i = Store.shared.items.firstIndex(where: { $0.id == item.id }) {
                        Store.shared.items[i].matrixX = newX
                        Store.shared.items[i].matrixY = newY
                    }
                }
        )
        .onTapGesture { onTap() }
        .onAppear {
            let x = item.matrixX ?? Double.random(in: 0.2...0.8)
            let y = item.matrixY ?? Double.random(in: 0.25...0.75)
            position = CGPoint(x: x * bounds.width, y: y * bounds.height)
        }
        .animation(.spring(duration: 0.2), value: isDragging)
    }

    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}
