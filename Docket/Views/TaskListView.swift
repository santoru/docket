// TaskListView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Main view showing active tasks with search, sort modes, and swipe actions.
struct TaskListView: View {
    @Binding var path: [NavDestination]
    var store = Store.shared

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("sortMode") private var sortModeRaw: Int = SortMode.custom.rawValue

    @State private var showConfetti = false
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showSortBar = false
    @State private var showUndo = false
    @State private var undoMessage = ""
    @State private var undoItem: TodoItem?
    @State private var undoAction: UndoAction = .complete
    @State private var undoTrigger = 0

    private enum UndoAction { case complete, delete }
    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }
    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .custom }

    private var filteredTasks: [TodoItem] {
        guard !searchText.isEmpty else { return store.activeTasks }
        return store.activeTasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                if showSortBar { sortBar }
                if showSearch { searchBar }
                taskContent
            }
            ConfettiOverlay(isActive: $showConfetti)
            UndoToast(message: undoMessage, trigger: undoTrigger, onUndo: performUndo, isVisible: $showUndo)
                .padding(.bottom, 8)
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidClose)) { _ in
            withAnimation(.easeOut(duration: 0.15)) {
                showSearch = false
                showSortBar = false
                searchText = ""
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                if store.lists.count > 1 {
                    Menu {
                        ForEach(store.lists) { list in
                            Button {
                                store.switchList(list)
                            } label: {
                                HStack {
                                    Text(list.name)
                                    if list.id == store.activeListId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(store.activeList.name).font(.title2.bold())
                            Image(systemName: "chevron.down").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(L10n.appName).font(.title2.bold())
                }
                let count = store.activeTasks.count
                Text(count == 1 ? L10n.oneTask : L10n.taskCount(count))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            headerButton(icon: showSortBar ? "checkmark.circle" : "arrow.up.arrow.down",
                         color: showSortBar ? .green : accent) {
                withAnimation(.spring(duration: 0.25)) { showSortBar.toggle() }
            }
            headerButton(icon: "magnifyingglass", color: accent) {
                withAnimation(.spring(duration: 0.25)) { showSearch.toggle(); if !showSearch { searchText = "" } }
            }
            headerButton(icon: "square.grid.2x2", color: accent) { path.append(.matrix) }
            headerButton(icon: "tray.full", color: accent) { path.append(.completed) }
            headerButton(icon: "gear", color: accent) { path.append(.settings) }
            headerButton(icon: "plus", color: .green) { path.append(.create) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func headerButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body).foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                sortPill("Custom", mode: .custom)
                sortPill("By Due Date", mode: .byDueDate)
                Spacer()
            }
            if !store.labelsForActiveList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        labelFilterPill(name: "All", color: accent, id: nil)
                        ForEach(store.labelsForActiveList) { label in
                            labelFilterPill(name: label.name, color: label.color, id: label.id)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func labelFilterPill(name: String, color: Color, id: UUID?) -> some View {
        let isActive = store.activeLabelFilter == id
        return Button {
            withAnimation(.spring(duration: 0.25)) { store.activeLabelFilter = id }
        } label: {
            Text(name)
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(isActive ? color.opacity(0.2) : Color.clear))
                .overlay(Capsule().stroke(isActive ? color : Color.secondary.opacity(0.3), lineWidth: 1))
                .foregroundStyle(isActive ? color : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func sortPill(_ label: String, mode: SortMode) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { sortModeRaw = mode.rawValue }
        } label: {
            Text(label)
                .font(.caption.weight(sortMode == mode ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(sortMode == mode ? accent : .clear)
                )
                .foregroundStyle(sortMode == mode ? .white : .secondary)
                .overlay(Capsule().stroke(sortMode == mode ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
            TextField("Search tasks...", text: $searchText).textFieldStyle(.plain).font(.body)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))
        
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Task Content

    @ViewBuilder
    private var taskContent: some View {
        if store.activeTasks.isEmpty {
            emptyState
        } else if sortMode == .byDueDate && searchText.isEmpty {
            groupedList
        } else {
            customList
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal").font(.system(size: 36)).foregroundStyle(.tertiary)
                Text("All clear!").font(.body).foregroundStyle(.secondary)
                Button { path.append(.create) } label: {
                    Text("Add your first task")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(accent)
                }.buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Custom Sort List

    private var customList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                let tasks = filteredTasks
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, item in
                    SwipeableTaskRow(
                        item: item,
                        editMode: showSortBar && sortMode == .custom,
                        onComplete: { completeItem(item) },
                        onDelete: { deleteItem(item) },
                        onTap: { path.append(.detail(item)) },
                        onMoveUp: index > 0 ? {
                            withAnimation(.spring(duration: 0.25)) {
                                store.move(from: IndexSet(integer: index), to: index - 1)
                            }
                        } : nil,
                        onMoveDown: index < tasks.count - 1 ? {
                            withAnimation(.spring(duration: 0.25)) {
                                store.move(from: IndexSet(integer: index), to: index + 2)
                            }
                        } : nil
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    // MARK: - Grouped by Due Date List

    private var groupedList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(store.groupedByDueDate, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeader(title: group.title, color: sectionColor(group.color))
                        ForEach(group.tasks) { item in
                            SwipeableTaskRow(
                                item: item,
                                editMode: false,
                                onComplete: { completeItem(item) },
                                onDelete: { deleteItem(item) },
                                onTap: { path.append(.detail(item)) },
                                onMoveUp: nil,
                                onMoveDown: nil
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    private func sectionHeader(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(color)
            Rectangle().fill(color.opacity(0.3)).frame(height: 0.5)
        }
        .padding(.top, 4)
    }

    private func sectionColor(_ name: String) -> Color {
        switch name {
        case "red": .red
        case "orange": .orange
        case "blue": .blue
        default: .gray
        }
    }

    // MARK: - Actions

    private func completeItem(_ item: TodoItem) {
        showConfetti = true
        undoItem = item
        undoAction = .complete
        undoMessage = L10n.taskCompleted
        undoTrigger += 1
        withAnimation(.spring(duration: 0.3)) {
            store.complete(item)
            showUndo = true
        }
    }

    private func deleteItem(_ item: TodoItem) {
        undoItem = item
        undoAction = .delete
        undoMessage = L10n.taskDeleted
        undoTrigger += 1
        withAnimation(.spring(duration: 0.3)) {
            store.delete(item)
            showUndo = true
        }
    }

    private func performUndo() {
        guard let item = undoItem else { return }
        withAnimation(.spring(duration: 0.3)) {
            switch undoAction {
            case .complete: store.restore(item)
            case .delete: store.add(item)
            }
        }
        undoItem = nil
    }
}
