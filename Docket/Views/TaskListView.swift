// TaskListView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Shared coordinate-space name for the reorderable task list.
enum TaskListCoordinateSpace { static let name = "taskList" }

/// Reports each task row's frame (in the list's coordinate space) so the
/// drag-reorder coordinator can compute insertion indices for variable-height rows.
struct RowFrameKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

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
    @AppStorage("showMatrixButton") private var showMatrixButton = true
    @AppStorage("showCompletedButton") private var showCompletedButton = true
    @AppStorage("showConfetti") private var confettiEnabled = true

    // Drag-to-reorder state
    @State private var draggingId: UUID?
    @State private var dragStartCenterY: CGFloat?
    @State private var dragTranslationY: CGFloat = 0
    @State private var liveOrder: [TodoItem]?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var showModeToast = false

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }
    private var sortMode: SortMode { SortMode(rawValue: sortModeRaw) ?? .custom }

    private var filteredTasks: [TodoItem] {
        guard !searchText.isEmpty else { return store.activeTasks }
        return store.activeTasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Reorder is allowed only on the full, unfiltered active list — disabled
    /// while searching or filtering by label (the visible set is partial).
    private var reorderEnabled: Bool {
        searchText.isEmpty && store.activeLabelFilter == nil
    }

    /// Tasks shown in custom mode: the live drag order while reordering,
    /// otherwise the stored/filtered order.
    private var displayedCustomTasks: [TodoItem] {
        liveOrder ?? filteredTasks
    }

    /// Vertical offset that keeps the lifted row under the cursor.
    private var liftOffset: CGFloat {
        guard let id = draggingId, let startY = dragStartCenterY else { return 0 }
        let fingerY = startY + dragTranslationY
        let slotY = rowFrames[id]?.midY ?? startY
        return fingerY - slotY
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                if showSortBar { sortBar }
                if showSearch { searchBar }
                taskContent
            }
            .overlay(alignment: .top) {
                if showModeToast {
                    Text("Switched to Custom order")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.regularMaterial))
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
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
                         label: showSortBar ? "Hide sort options" : "Sort options",
                         color: showSortBar ? .green : accent) {
                withAnimation(.spring(duration: 0.25)) { showSortBar.toggle() }
            }
            headerButton(icon: "magnifyingglass", label: "Search", color: accent) {
                withAnimation(.spring(duration: 0.25)) { showSearch.toggle(); if !showSearch { searchText = "" } }
            }
            if showMatrixButton { headerButton(icon: "square.grid.2x2", label: "Eisenhower Matrix", color: accent) { path.append(.matrix) } }
            if showCompletedButton { headerButton(icon: "tray.full", label: "Completed tasks", color: accent) { path.append(.completed) } }
            headerButton(icon: "gear", label: "Settings", color: accent) { path.append(.settings) }
            headerButton(icon: "plus", label: "New task", color: .green) { path.append(.create) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func headerButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body).foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
        } else if !searchText.isEmpty && filteredTasks.isEmpty {
            noResultsState
        } else {
            unifiedList
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

    private var noResultsState: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 36)).foregroundStyle(.tertiary)
                Text(L10n.noResults).font(.body).foregroundStyle(.secondary)
                Text("No tasks match \u{201C}\(searchText)\u{201D}")
                    .font(.caption).foregroundStyle(.tertiary)
                    .lineLimit(1).truncationMode(.middle)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - Unified List

    /// A flat list item: either a due-date section header or a task. Keeping
    /// everything in one LazyVStack (rather than separate grouped/custom views)
    /// means a row's identity — and any in-flight reorder gesture — survives
    /// when a drag switches the sort from By Due Date to Custom.
    private struct ListRow: Identifiable {
        enum Kind { case header(title: String, color: String); case task(TodoItem) }
        let id: String
        let kind: Kind
    }

    private var listRows: [ListRow] {
        // While dragging we are always in Custom (the drag switched us there),
        // so render the flat custom order with no section headers.
        if sortMode == .byDueDate && searchText.isEmpty && draggingId == nil {
            var rows: [ListRow] = []
            for group in store.groupedByDueDate {
                rows.append(ListRow(id: "header-\(group.title)", kind: .header(title: group.title, color: group.color)))
                rows.append(contentsOf: group.tasks.map { ListRow(id: $0.id.uuidString, kind: .task($0)) })
            }
            return rows
        } else {
            return displayedCustomTasks.map { ListRow(id: $0.id.uuidString, kind: .task($0)) }
        }
    }

    private var unifiedList: some View {
        VScroll {
            LazyVStack(spacing: 8) {
                ForEach(listRows) { row in
                    switch row.kind {
                    case .header(let title, let color):
                        sectionHeader(title: title, color: sectionColor(color))
                    case .task(let item):
                        taskRow(item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .coordinateSpace(name: TaskListCoordinateSpace.name)
            .onPreferenceChange(RowFrameKey.self) { rowFrames = $0 }
            .animation(.spring(duration: 0.28), value: draggingId)
        }
    }

    @ViewBuilder
    private func taskRow(_ item: TodoItem) -> some View {
        let lifted = draggingId == item.id
        SwipeableTaskRow(
            item: item,
            reorderEnabled: reorderEnabled,
            isLifted: lifted,
            onComplete: { completeItem(item) },
            onDelete: { deleteItem(item) },
            onTap: { path.append(.detail(item)) },
            onReorderBegin: { beginReorder(item) },
            onReorderChange: { updateReorder(translationY: $0) },
            onReorderEnd: { endReorder() }
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: RowFrameKey.self,
                    value: [item.id: geo.frame(in: .named(TaskListCoordinateSpace.name))]
                )
            }
        )
        .offset(y: lifted ? liftOffset : 0)
        .scaleEffect(lifted ? 1.03 : 1.0)
        .shadow(color: .black.opacity(lifted ? 0.18 : 0),
                radius: lifted ? 8 : 0, y: lifted ? 4 : 0)
        .zIndex(lifted ? 1 : 0)
        .accessibilityActions {
            if reorderEnabled && sortMode == .custom {
                Button("Move up") { moveByAccessibility(item, by: -1) }
                Button("Move down") { moveByAccessibility(item, by: 1) }
            }
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

    // MARK: - Reorder

    private func beginReorder(_ item: TodoItem) {
        guard reorderEnabled else { return }
        if sortMode == .byDueDate {
            // Adopt the currently-visible due-date order as the explicit custom
            // order, then switch to Custom so the drag continues in a flat list.
            let flat = store.groupedByDueDate.flatMap { $0.tasks }
            store.applyManualOrder(flat.map(\.id))
            sortModeRaw = SortMode.custom.rawValue
            showModeToastBriefly()
        }
        draggingId = item.id
        dragStartCenterY = rowFrames[item.id]?.midY
        dragTranslationY = 0
        liveOrder = displayedCustomTasks
    }

    private func showModeToastBriefly() {
        withAnimation(.spring(duration: 0.25)) { showModeToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) { showModeToast = false }
        }
    }

    private func updateReorder(translationY: CGFloat) {
        guard let id = draggingId, let startY = dragStartCenterY, var order = liveOrder else { return }
        dragTranslationY = translationY
        let fingerY = startY + translationY
        // Insertion index = number of other rows whose midpoint sits above the finger.
        var target = 0
        for t in order where t.id != id {
            if let f = rowFrames[t.id], f.midY < fingerY { target += 1 }
        }
        guard let current = order.firstIndex(where: { $0.id == id }) else { return }
        if current != target {
            let moved = order.remove(at: current)
            order.insert(moved, at: min(target, order.count))
            withAnimation(.spring(duration: 0.25)) { liveOrder = order }
        }
    }

    private func endReorder() {
        if let order = liveOrder {
            store.applyManualOrder(order.map(\.id))
        }
        withAnimation(.spring(duration: 0.25)) { draggingId = nil }
        dragStartCenterY = nil
        dragTranslationY = 0
        liveOrder = nil
    }

    /// VoiceOver / keyboard fallback for reordering without a drag.
    private func moveByAccessibility(_ item: TodoItem, by delta: Int) {
        let tasks = filteredTasks
        guard let idx = tasks.firstIndex(where: { $0.id == item.id }) else { return }
        let target = idx + delta
        guard target >= 0, target < tasks.count else { return }
        var order = tasks
        let moved = order.remove(at: idx)
        order.insert(moved, at: target)
        withAnimation(.spring(duration: 0.25)) { store.applyManualOrder(order.map(\.id)) }
    }

    // MARK: - Actions

    private func completeItem(_ item: TodoItem) {
        if confettiEnabled { showConfetti = true }
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
