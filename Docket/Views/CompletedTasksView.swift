// CompletedTasksView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Shows completed tasks with the ability to restore them.
struct CompletedTasksView: View {
    @Binding var path: [NavDestination]
    var store = Store.shared

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("useGlass") private var useGlass = true

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if store.completedTasks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.system(size: 36)).foregroundStyle(.tertiary)
                    Text("Nothing here yet").font(.body).foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(store.completedTasks) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.body).strikethrough().foregroundStyle(.secondary)
                                    if let done = item.completedAt {
                                        Text(done, style: .relative)
                                            .font(.caption).foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Button { withAnimation { store.restore(item) } } label: {
                                    Image(systemName: "arrow.uturn.backward.circle").foregroundStyle(accent)
                                }.buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(useGlass ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white.opacity(0.65)))
                            )
                            .overlay(useGlass ? nil : RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 0.5))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(Circle().fill(.quaternary.opacity(0.5)))
            }.buttonStyle(.plain)
            Spacer()
            Text("Completed").font(.headline)
            Text("(\(store.completedTasks.count))").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
