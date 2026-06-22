// TaskListView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit

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

/// Resolves the enclosing NSScrollView so the reorder coordinator can drive
/// edge auto-scrolling during a drag (SwiftUI offers no offset control on
/// macOS 14, so we manipulate the AppKit clip view directly).
struct ScrollViewAccessor: NSViewRepresentable {
    var onResolve: (NSScrollView) -> Void
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { if let sv = v.enclosingScrollView { onResolve(sv) } }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { if let sv = nsView.enclosingScrollView { onResolve(sv) } }
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
    @State private var dragStartFrame: CGRect?
    @State private var liftScale: CGFloat = 1.0
    @State private var showModeToast = false

    // Autoscroll (drives the AppKit clip view while dragging near an edge)
    @State private var scrollView: NSScrollView?
    @State private var autoscrollDir: Int = 0          // -1 up, 0 idle, +1 down
    @State private var autoscrollTimer: Timer?
    @State private var autoscrollAccumulated: CGFloat = 0

    /// Edge auto-scroll while dragging near the top/bottom of the list.
    private let autoscrollEnabled = true

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

    /// Finger position in the list's content space: gesture start + drag
    /// translation + any distance auto-scrolled while held near an edge.
    private var fingerContentY: CGFloat {
        (dragStartCenterY ?? 0) + dragTranslationY + autoscrollAccumulated
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
                    Text(L10n.switchedToCustom)
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
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(list.color)
                                    Text(list.name)
                                    if list.id == store.activeListId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(store.activeList.color)
                                .frame(width: 8, height: 8)
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
                         label: showSortBar ? L10n.a11yHideSortOptions : L10n.a11ySortOptions,
                         color: showSortBar ? .green : accent) {
                withAnimation(.spring(duration: 0.25)) { showSortBar.toggle() }
            }
            headerButton(icon: "magnifyingglass", label: L10n.a11ySearch, color: accent) {
                withAnimation(.spring(duration: 0.25)) { showSearch.toggle(); if !showSearch { searchText = "" } }
            }
            if showMatrixButton { headerButton(icon: "square.grid.2x2", label: L10n.eisenhowerMatrix, color: accent) { path.append(.matrix) } }
            if showCompletedButton { headerButton(icon: "tray.full", label: L10n.a11yCompletedTasks, color: accent) { path.append(.completed) } }
            headerButton(icon: "gear", label: L10n.settings, color: accent) { path.append(.settings) }
            headerButton(icon: "plus", label: L10n.a11yNewTask, color: .green) { path.append(.create) }
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
                sortPill(L10n.sortCustom, mode: .custom)
                sortPill(L10n.sortByDueDate, mode: .byDueDate)
                sortPill(L10n.sortByPriority, mode: .byPriority)
                Spacer()
            }
            if !store.labelsForActiveList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        labelFilterPill(name: "All", color: accent, id: nil)
                        ForEach(store.labelsForActiveList) { label in
                            labelFilterPill(name: label.name, color: label.color.adaptedForCurrentScheme(themeRaw: themeRaw), id: label.id)
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
            TextField(L10n.searchPlaceholder, text: $searchText).textFieldStyle(.plain).font(.body)
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
                Text(L10n.allClear).font(.body).foregroundStyle(.secondary)
                Button { path.append(.create) } label: {
                    Text(L10n.addFirstTask)
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
                Text(L10n.noResultsDetail(searchText))
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

    /// The section grouping for the current non-custom sort mode (nil in Custom).
    private var currentGroups: [(title: String, color: String, tasks: [TodoItem])]? {
        switch sortMode {
        case .byDueDate: return store.groupedByDueDate
        case .byPriority: return store.groupedByPriority
        case .custom: return nil
        }
    }

    private var listRows: [ListRow] {
        // While dragging we are always in Custom (the drag switched us there),
        // so render the flat custom order with no section headers.
        if let groups = currentGroups, searchText.isEmpty, draggingId == nil {
            var rows: [ListRow] = []
            for group in groups {
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
            VStack(spacing: 8) {
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
            .padding(.bottom, 12)
            .coordinateSpace(name: TaskListCoordinateSpace.name)
            .background(ScrollViewAccessor { scrollView = $0 })
            .onPreferenceChange(RowFrameKey.self) { rowFrames = $0 }
            .animation(.spring(duration: 0.28), value: draggingId)
            .overlay(alignment: .topLeading) { floatingCard }
        }
    }

    /// The lifted card, drawn as a floating copy that tracks the cursor with pure
    /// translation (instant follow). The real row stays in the list as an
    /// invisible placeholder so the other rows part around the insertion point.
    @ViewBuilder
    private var floatingCard: some View {
        if let id = draggingId,
           let item = (liveOrder ?? filteredTasks).first(where: { $0.id == id }),
           let f = dragStartFrame {
            TaskRowView(item: item, onComplete: {})
                .frame(width: f.width, height: f.height)
                .scaleEffect(liftScale)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                .offset(x: f.minX, y: f.minY + dragTranslationY + autoscrollAccumulated)
                .allowsHitTesting(false)
                .onAppear {
                    // Grow smoothly into the lifted size instead of popping in.
                    withAnimation(.spring(duration: 0.22, bounce: 0.35)) { liftScale = 1.03 }
                }
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
        // While lifted, this row is an invisible placeholder holding the gap (and
        // the gesture); the floating overlay draws the actual card at the cursor.
        .opacity(lifted ? 0 : 1)
        .accessibilityActions {
            if reorderEnabled && sortMode == .custom {
                Button(L10n.moveUp) { moveByAccessibility(item, by: -1) }
                Button(L10n.moveDown) { moveByAccessibility(item, by: 1) }
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
        if sortMode != .custom {
            // Adopt the currently-visible grouped order as the explicit custom
            // order, then switch to Custom so the drag continues in a flat list.
            let flat = (currentGroups ?? []).flatMap { $0.tasks }
            store.applyManualOrder(flat.map(\.id))
            sortModeRaw = SortMode.custom.rawValue
            showModeToastBriefly()
        }
        draggingId = item.id
        dragStartCenterY = rowFrames[item.id]?.midY
        dragStartFrame = rowFrames[item.id]
        dragTranslationY = 0
        autoscrollAccumulated = 0
        liveOrder = displayedCustomTasks
        if autoscrollEnabled { startAutoscrollTimer() }
    }

    private func showModeToastBriefly() {
        withAnimation(.spring(duration: 0.25)) { showModeToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) { showModeToast = false }
        }
    }

    private func updateReorder(translationY: CGFloat) {
        guard let id = draggingId else { return }
        if dragStartCenterY == nil { dragStartCenterY = rowFrames[id]?.midY }
        dragTranslationY = translationY
        applyReorderTarget()
        if autoscrollEnabled { updateAutoscrollZone() }
    }

    /// Move the dragged item to the insertion index implied by `fingerContentY`,
    /// so the other rows part to make room as the card is dragged over them.
    private func applyReorderTarget() {
        guard let id = draggingId, var order = liveOrder else { return }
        let y = fingerContentY
        var target = 0
        for t in order where t.id != id {
            if let f = rowFrames[t.id], f.midY < y { target += 1 }
        }
        guard let current = order.firstIndex(where: { $0.id == id }) else { return }
        if current != target {
            let moved = order.remove(at: current)
            order.insert(moved, at: min(target, order.count))
            withAnimation(.spring(duration: 0.25)) { liveOrder = order }
        }
    }

    private func endReorder() {
        stopAutoscroll()
        guard draggingId != nil else { return }   // idempotent — watchdog may also call this
        if let order = liveOrder {
            store.applyManualOrder(order.map(\.id))
        }
        withAnimation(.spring(duration: 0.25)) { draggingId = nil }
        dragStartCenterY = nil
        dragStartFrame = nil
        liftScale = 1.0
        dragTranslationY = 0
        autoscrollAccumulated = 0
        liveOrder = nil
    }

    // MARK: - Autoscroll

    /// Decide whether the cursor is in the top/bottom edge band of the visible
    /// scroll area. Compares the cursor's content-space position against the
    /// scroll view's visible rect — both in the document's coordinate space, so
    /// it stays correct no matter how far the list is scrolled.
    private func updateAutoscrollZone() {
        guard let sv = scrollView else { autoscrollDir = 0; return }
        let visible = sv.contentView.documentVisibleRect
        guard visible.height > 0 else { autoscrollDir = 0; return }
        let band: CGFloat = 50
        let y = fingerContentY
        if y < visible.minY + band { autoscrollDir = -1 }
        else if y > visible.maxY - band { autoscrollDir = 1 }
        else { autoscrollDir = 0 }
    }

    private func startAutoscrollTimer() {
        autoscrollTimer?.invalidate()
        autoscrollAccumulated = 0
        // .common mode so the timer keeps firing during gesture event tracking.
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in stepAutoscroll() }
        RunLoop.main.add(t, forMode: .common)
        autoscrollTimer = t
    }

    private func stepAutoscroll() {
        guard autoscrollDir != 0, let sv = scrollView else { return }
        let clip = sv.contentView
        let flipped = sv.documentView?.isFlipped ?? true
        let speed: CGFloat = 9
        let maxY = max(0, (sv.documentView?.frame.height ?? 0) - clip.bounds.height)
        let current = clip.bounds.origin.y
        // Map intent (-1 up / +1 down) to clip-space direction (depends on flip).
        let clipDir: CGFloat = (flipped ? 1 : -1) * CGFloat(autoscrollDir)
        let proposed = min(max(0, current + clipDir * speed), maxY)
        let delta = proposed - current
        guard abs(delta) > 0.01 else { return }
        clip.scroll(to: NSPoint(x: clip.bounds.origin.x, y: proposed))
        sv.reflectScrolledClipView(clip)
        // Content-space finger advances in the intent direction by the amount scrolled.
        autoscrollAccumulated += CGFloat(autoscrollDir) * abs(delta)
        applyReorderTarget()
    }

    private func stopAutoscroll() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
        autoscrollDir = 0
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
