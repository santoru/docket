// SettingsView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit
import EventKit
import ServiceManagement
import Carbon.HIToolbox
internal import UniformTypeIdentifiers

/// App preferences: reminders, hotkey, launch at login, theme.
struct SettingsView: View {
    @Binding var path: [NavDestination]
    var store = Store.shared

    @AppStorage("defaultReminderOffset") private var defaultOffset: Int = ReminderOffset.tenMinutes.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("useGlass") private var useGlass = true
    @AppStorage("notifSound") private var notifSound = "default"
    @AppStorage("badgeAllLists") private var badgeAllLists = false
    @AppStorage("multiLineTask") private var multiLineTask = false
    @AppStorage("showConfetti") private var showConfetti = true
    @AppStorage("hotkeyEnabled") private var hotkeyEnabled = true
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode = kVK_ANSI_D
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers = Int(cmdKey | shiftKey)
    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("customSat") private var customSat: Double = 0.3

    private var hotkeyLabel: String {
        var parts: [String] = []
        let mods = UInt32(hotkeyModifiers)
        if mods & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if mods & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if mods & UInt32(optionKey) != 0 { parts.append("⌥") }
        if mods & UInt32(controlKey) != 0 { parts.append("⌃") }
        let keys: [Int: String] = [
            kVK_ANSI_D: "D", kVK_ANSI_T: "T", kVK_ANSI_K: "K",
            kVK_ANSI_J: "J", kVK_ANSI_N: "N", kVK_ANSI_O: "O"
        ]
        parts.append(keys[hotkeyKeyCode] ?? "D")
        return parts.joined()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VScroll {
                VStack(spacing: 12) {
                    groupHeader(L10n.groupGeneral, first: true)
                    generalSection
                    hotkeySection

                    groupHeader(L10n.groupAppearance)
                    themeSection
                    displaySection
                    matrixSection

                    groupHeader(L10n.groupNotifications)
                    reminderSection

                    groupHeader(L10n.groupOrganize)
                    listsSection
                    labelsSection

                    groupHeader(L10n.groupSyncData)
                    remindersSection
                    dataSection

                    groupHeader("Support")
                    card { TipJarView() }

                    VStack(spacing: 4) {
                        Text("Docket v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                            .font(.caption).foregroundStyle(.tertiary)
                        Link("github.com/santoru/docket", destination: URL(string: "https://github.com/santoru/docket")!)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
        }
        .alert(L10n.deleteListTitle, isPresented: $showDeleteConfirm) {
            Button(L10n.delete, role: .destructive) {
                if let list = listToDelete { withAnimation { store.deleteList(list) } }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            if let list = listToDelete {
                let count = store.items.filter { $0.listId == list.id }.count
                Text(L10n.deleteListMessage(list.name, count))
            }
        }
        .alert(L10n.clearCompletedTitle, isPresented: $showClearConfirm) {
            Button(L10n.clearNTasks(store.completedTasks.count), role: .destructive) {
                withAnimation { store.clearCompleted() }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.clearCompletedMessage)
        }
        .alert(L10n.deleteLabelTitle, isPresented: $showLabelDeleteConfirm) {
            Button(L10n.delete, role: .destructive) {
                if let label = labelToDelete { withAnimation { store.deleteLabel(label) } }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            if let label = labelToDelete {
                let count = store.items.filter { $0.labelIds.contains(label.id) }.count
                Text(L10n.deleteLabelMessage(label.name, count))
            }
        }
    }

    private var header: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(Circle().fill(.quaternary.opacity(0.5)))
            }.buttonStyle(.plain)
            Spacer()
            Text(L10n.settings).font(.headline)
            Spacer()
            Button { path.removeLast() } label: { Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(Circle().fill(.quaternary.opacity(0.5))) }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sections

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    private var reminderSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.defaultReminder).font(.subheadline)
                    Spacer()
                    Menu {
                        ForEach(ReminderOffset.allCases) { r in
                            Button(r.displayName) { defaultOffset = r.rawValue }
                        }
                    } label: {
                        Text((ReminderOffset(rawValue: defaultOffset) ?? .tenMinutes).displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
                Divider()
                HStack {
                    Text(L10n.sound).font(.subheadline)
                    Spacer()
                    Menu {
                        Button(L10n.soundDefault) { setSound("default") }
                        Button("Ping") { setSound("Ping") }
                        Button("Glass") { setSound("Glass") }
                        Button("Pop") { setSound("Pop") }
                        Button("Purr") { setSound("Purr") }
                        Button("Submarine") { setSound("Submarine") }
                        Button("Tink") { setSound("Tink") }
                        Button(L10n.soundNone) { setSound("none") }
                    } label: {
                        Text(notifSound == "default" ? L10n.soundDefault : notifSound == "none" ? L10n.soundNone : notifSound)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
                Divider()
                HStack {
                    Text(L10n.badgeCounts).font(.subheadline)
                    Spacer()
                    Menu {
                        Button(L10n.currentList) { badgeAllLists = false }
                        Button(L10n.allLists) { badgeAllLists = true }
                    } label: {
                        Text(badgeAllLists ? L10n.allLists : L10n.currentList)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func setSound(_ sound: String) {
        notifSound = sound
        if sound != "none" {
            if sound == "default" {
                NSSound.beep()
            } else {
                NSSound(named: sound)?.play()
            }
        }
    }

    private var generalSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                ThemedToggle(label: L10n.launchAtLogin, isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        if on { try? SMAppService.mainApp.register() }
                        else { SMAppService.mainApp.unregister { _ in } }
                    }
                Divider()
                ThemedToggle(label: L10n.multiLineTasks, isOn: $multiLineTask)
            }
        }
    }

    private var hotkeySection: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.keyboard).font(.body.weight(.medium))
                ThemedToggle(label: L10n.globalShortcut, isOn: $hotkeyEnabled)
                    .onChange(of: hotkeyEnabled) { _, _ in AppDelegate.shared?.registerHotkey() }
                if hotkeyEnabled {
                    HStack {
                        Text(L10n.shortcut).font(.subheadline)
                        Spacer()
                        Menu {
                            Button("⌘⇧D") { setHotkey(kVK_ANSI_D, Int(cmdKey | shiftKey)) }
                            Button("⌘⇧T") { setHotkey(kVK_ANSI_T, Int(cmdKey | shiftKey)) }
                            Button("⌘⇧K") { setHotkey(kVK_ANSI_K, Int(cmdKey | shiftKey)) }
                            Button("⌃⌥D") { setHotkey(kVK_ANSI_D, Int(controlKey | optionKey)) }
                            Button("⌃⌥T") { setHotkey(kVK_ANSI_T, Int(controlKey | optionKey)) }
                            Button("⌘⌥D") { setHotkey(kVK_ANSI_D, Int(cmdKey | optionKey)) }
                        } label: {
                            Text(hotkeyLabel)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                                .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Reminders Sync

    @AppStorage("remindersSyncEnabled") private var remindersSyncEnabled = false
    @State private var availableCalendars: [EKCalendar] = []
    @State private var syncedCalendarIds: Set<String> = []

    private var remindersSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.remindersSync).font(.body.weight(.medium))
                ThemedToggle(label: L10n.syncWithReminders, isOn: $remindersSyncEnabled)
                    .onChange(of: remindersSyncEnabled) { _, on in
                        if on { enableSync() } else { disableSync() }
                    }

                if remindersSyncEnabled {
                    if availableCalendars.isEmpty {
                        Text(L10n.noRemindersAccess).font(.caption).foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.listsToSync).font(.caption).foregroundStyle(.secondary)
                            ForEach(availableCalendars, id: \.calendarIdentifier) { cal in
                                HStack(spacing: 8) {
                                    Image(systemName: syncedCalendarIds.contains(cal.calendarIdentifier) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(syncedCalendarIds.contains(cal.calendarIdentifier) ? accent : .secondary)
                                        .font(.body)
                                    Text(cal.title).font(.subheadline)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { toggleCalendar(cal) }
                            }
                        }

                        if let lastSync = RemindersSync.shared.lastSyncDate {
                            HStack(spacing: 4) {
                                Text(L10n.lastSync)
                                Text(lastSync, style: .relative)
                            }
                            .font(.caption).foregroundStyle(.tertiary)
                        }

                        Button { RemindersSync.shared.syncAll() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath").font(.caption)
                                Text(L10n.syncNow).font(.caption.weight(.medium))
                            }.foregroundStyle(accent)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear { loadSyncState() }
    }

    private func enableSync() {
        Task {
            let granted = await RemindersSync.shared.requestAccess()
            if granted {
                availableCalendars = RemindersSync.shared.availableCalendars()
                // Link the default/active list to a Reminders calendar
                let defaultList = store.lists.first(where: { $0.isDefault }) ?? store.lists[0]
                let calName = defaultList.name == "Default" ? "Docket" : defaultList.name

                // Check if calendar already exists
                if let existing = availableCalendars.first(where: { $0.title == calName }) {
                    // Link existing calendar to default list
                    if let i = store.lists.firstIndex(where: { $0.id == defaultList.id }) {
                        store.lists[i].remindersCalendarId = existing.calendarIdentifier
                    }
                    syncedCalendarIds.insert(existing.calendarIdentifier)
                } else if let newCal = RemindersSync.shared.findOrCreateCalendar(named: calName) {
                    if let i = store.lists.firstIndex(where: { $0.id == defaultList.id }) {
                        store.lists[i].remindersCalendarId = newCal.calendarIdentifier
                    }
                    syncedCalendarIds.insert(newCal.calendarIdentifier)
                }

                // Also link any other Docket lists that have matching Reminders calendars
                for j in store.lists.indices where store.lists[j].remindersCalendarId == nil && !store.lists[j].isDefault {
                    if let match = availableCalendars.first(where: { $0.title == store.lists[j].name }) {
                        store.lists[j].remindersCalendarId = match.calendarIdentifier
                        syncedCalendarIds.insert(match.calendarIdentifier)
                    }
                }

                RemindersSync.shared.startObserving()
                saveSyncedIds()
                store.persist()
                RemindersSync.shared.syncAll()
            } else {
                remindersSyncEnabled = false
            }
        }
    }

    private func disableSync() {
        RemindersSync.shared.stopObserving()
        syncedCalendarIds.removeAll()
        saveSyncedIds()
    }

    private func toggleCalendar(_ cal: EKCalendar) {
        let id = cal.calendarIdentifier
        if syncedCalendarIds.contains(id) {
            syncedCalendarIds.remove(id)
            // Unlink from Docket list
            if let i = store.lists.firstIndex(where: { $0.remindersCalendarId == id }) {
                store.lists[i].remindersCalendarId = nil
            }
        } else {
            syncedCalendarIds.insert(id)
            linkCalendar(cal)
        }
        saveSyncedIds()
        RemindersSync.shared.syncAll()
    }

    private func linkCalendar(_ cal: EKCalendar) {
        let id = cal.calendarIdentifier
        // Find or create matching Docket list
        if let i = store.lists.firstIndex(where: { $0.remindersCalendarId == id }) {
            _ = i // already linked
        } else if let i = store.lists.firstIndex(where: { $0.name == cal.title && $0.remindersCalendarId == nil }) {
            store.lists[i].remindersCalendarId = id
        } else {
            var newList = TaskList(name: cal.title, remindersCalendarId: id)
            newList.remindersCalendarId = id
            store.lists.append(newList)
        }
    }

    private func loadSyncState() {
        if remindersSyncEnabled {
            RemindersSync.shared.checkAccess()
            if RemindersSync.shared.isAuthorized {
                availableCalendars = RemindersSync.shared.availableCalendars()
                syncedCalendarIds = Set(UserDefaults.standard.stringArray(forKey: "syncedCalendarIds") ?? [])
                RemindersSync.shared.startObserving()
            }
        }
    }

    private func saveSyncedIds() {
        UserDefaults.standard.set(Array(syncedCalendarIds), forKey: "syncedCalendarIds")
    }

    // MARK: - Lists

    @State private var editingListId: UUID?
    @State private var editingName = ""
    @State private var listToDelete: TaskList?
    @State private var showDeleteConfirm = false
    @State private var hoveredListId: UUID?
    @FocusState private var listNameFocused: Bool

    private var listsSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.lists).font(.body.weight(.medium))
                    Spacer()
                    Button {
                        store.addList(name: L10n.newList)
                        editingName = L10n.newList
                        editingListId = store.lists.last?.id
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(accent)
                    }.buttonStyle(.plain)
                }

                VStack(spacing: 4) {
                    ForEach(store.lists) { list in
                        HStack(spacing: 10) {
                            listColorSwatch(for: list)

                            if editingListId == list.id {
                                TextField(L10n.namePlaceholder, text: $editingName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .focused($listNameFocused)
                                    .onSubmit { commitListRename(list) }
                                    .onAppear {
                                        // Flicker false → true so every TextField gets a fresh
                                        // focus event, even if the previous row's edit left
                                        // `listNameFocused` set. NSTextField only runs its
                                        // select-all-on-first-responder hook on a clean focus
                                        // assignment, so without the flicker the second row's
                                        // text wouldn't be selected on auto-commit-then-switch.
                                        listNameFocused = false
                                        DispatchQueue.main.async { listNameFocused = true }
                                    }
                                Spacer()
                                Button {
                                    commitListRename(list)
                                } label: {
                                    Text(L10n.done).font(.caption.weight(.semibold)).foregroundStyle(accent)
                                }.buttonStyle(.plain)
                            } else {
                                Text(list.name)
                                    .font(.body)
                                    .foregroundStyle(list.id == store.activeListId ? .primary : .secondary)
                                Spacer()
                                let showActions = hoveredListId == list.id
                                HStack(spacing: 6) {
                                    RowActionButton(systemImage: "pencil",
                                                    label: L10n.rename,
                                                    tint: accent) {
                                        beginRenamingList(list)
                                    }
                                    if !list.isDefault {
                                        RowActionButton(systemImage: "trash.fill",
                                                        label: L10n.delete,
                                                        destructive: true) {
                                            requestDeleteList(list)
                                        }
                                    }
                                }
                                .opacity(showActions ? 1 : 0)
                                .animation(.easeOut(duration: 0.12), value: showActions)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(list.id == store.activeListId ? accent.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editingListId == nil { store.switchList(list) }
                        }
                        .onHover { isIn in
                            if isIn { hoveredListId = list.id }
                            else if hoveredListId == list.id { hoveredListId = nil }
                        }
                        .contextMenu {
                            Button(L10n.rename) { beginRenamingList(list) }
                            if !list.isDefault {
                                Button(L10n.delete, role: .destructive) { requestDeleteList(list) }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - List color swatch

    /// Tappable colored square shown at the leading edge of each list row in
    /// the Lists section. Wraps the shared `ColorSwatchButton` so the popover,
    /// palette, and persistence path are identical to every other color
    /// affordance in Settings.
    @ViewBuilder
    private func listColorSwatch(for list: TaskList) -> some View {
        let isActive = list.id == store.activeListId
        ColorSwatchButton(
            hex: listColorBinding(for: list.id),
            popoverTitle: list.name,
            ringColor: isActive ? accent : nil,
            onPopoverChange: { isOpen in
                refocusListNameIfEditing(closingPopover: !isOpen, list: list)
            }
        )
    }

    /// Binding that reads/writes the chosen list's `colorHex` directly on the
    /// store (and persists). Reading from the live store rather than a captured
    /// snapshot ensures the picker always reflects the current state.
    private func listColorBinding(for listId: UUID) -> Binding<String> {
        Binding(
            get: {
                store.lists.first(where: { $0.id == listId })?.resolvedHex
                    ?? ColorPalette.defaultHex
            },
            set: { newHex in
                guard let i = store.lists.firstIndex(where: { $0.id == listId }) else { return }
                store.lists[i].colorHex = newHex
                store.persist()
            }
        )
    }

    // MARK: - List actions

    private func beginRenamingList(_ list: TaskList) {
        // Auto-commit any pending rename on a different list before switching.
        if let inFlightId = editingListId, inFlightId != list.id,
           let inFlight = store.lists.first(where: { $0.id == inFlightId }) {
            commitListRename(inFlight)
        }
        editingName = list.name
        editingListId = list.id
    }

    /// Trims whitespace from `editingName` and persists it as the list's new
    /// name. If the trimmed result is empty, falls back to the list's current
    /// name so a stray Enter or empty Done doesn't blank the row.
    private func commitListRename(_ list: TaskList) {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = trimmed.isEmpty ? list.name : trimmed
        if newName != list.name {
            store.renameList(list, to: newName)
        }
        editingListId = nil
    }

    /// Re-grabs focus on the list rename TextField after a popover (color
    /// picker) dismisses, but only if the user is still editing this row.
    /// `@FocusState` is sticky after focus is yanked away, so we briefly
    /// flicker it false → true to force a re-focus.
    private func refocusListNameIfEditing(closingPopover: Bool, list: TaskList) {
        guard closingPopover, editingListId == list.id else { return }
        listNameFocused = false
        DispatchQueue.main.async { listNameFocused = true }
    }

    /// Routes a list-delete request through the confirmation alert when the
    /// list contains tasks; deletes silently otherwise.
    private func requestDeleteList(_ list: TaskList) {
        guard !list.isDefault else { return }
        let taskCount = store.items.filter { $0.listId == list.id }.count
        if taskCount > 0 {
            listToDelete = list
            showDeleteConfirm = true
        } else {
            withAnimation { store.deleteList(list) }
        }
    }

    // MARK: - Labels Settings

    @State private var editingLabelId: UUID?
    @State private var labelName = ""
    @State private var hoveredLabelId: UUID?
    @State private var labelToDelete: TaskLabel?
    @State private var showLabelDeleteConfirm = false
    @FocusState private var labelNameFocused: Bool

    private var labelsSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.labels).font(.body.weight(.medium))
                    Spacer()
                    Button { addNewLabel() } label: {
                        Image(systemName: "plus").font(.body.weight(.medium)).foregroundStyle(accent)
                    }.buttonStyle(.plain)
                }

                if store.labelsForActiveList.isEmpty {
                    Text(L10n.noLabels).font(.caption).foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 4) {
                        ForEach(store.labelsForActiveList) { label in
                            labelRow(label: label)
                        }
                    }
                }
            }
        }
    }

    /// Single row template that renders the label in either display or edit
    /// mode. The leading [color swatch | icon picker] cluster is identical
    /// in both — color and icon are picked through their popovers and persist
    /// immediately. The edit form therefore reduces to the name field, and
    /// the trailing affordance flips between [pencil + trash] (display) and
    /// a single [checkmark] (edit).
    private func labelRow(label: TaskLabel) -> some View {
        let isEditing = editingLabelId == label.id
        let showHover = hoveredLabelId == label.id
        let popoverTitle = isEditing
            ? (labelName.isEmpty ? L10n.newLabel : labelName)
            : label.name

        return HStack(spacing: 10) {
            ColorSwatchButton(
                hex: labelColorBinding(for: label.id),
                popoverTitle: popoverTitle,
                onPopoverChange: { isOpen in
                    refocusLabelNameIfEditing(closingPopover: !isOpen, label: label)
                }
            )
            IconPickerButton(
                icon: labelIconBinding(for: label.id),
                tint: label.color,
                popoverTitle: popoverTitle,
                onPopoverChange: { isOpen in
                    refocusLabelNameIfEditing(closingPopover: !isOpen, label: label)
                }
            )
            if isEditing {
                TextField(L10n.namePlaceholder, text: $labelName)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .focused($labelNameFocused)
                    .onSubmit { commitLabel(label) }
                    .onAppear {
                        // Flicker false → true so every TextField gets a fresh focus
                        // event. See the matching block in the list rename TextField
                        // for the rationale.
                        labelNameFocused = false
                        DispatchQueue.main.async { labelNameFocused = true }
                    }
            } else {
                Text(label.name).font(.subheadline)
            }
            Spacer()
            HStack(spacing: 6) {
                if isEditing {
                    RowActionButton(systemImage: "checkmark",
                                    label: L10n.done,
                                    tint: label.color) {
                        commitLabel(label)
                    }
                } else {
                    RowActionButton(systemImage: "pencil",
                                    label: L10n.edit,
                                    tint: label.color) {
                        beginEditingLabel(label)
                    }
                    RowActionButton(systemImage: "trash.fill",
                                    label: L10n.delete,
                                    destructive: true) {
                        requestDeleteLabel(label)
                    }
                }
            }
            .opacity(isEditing || showHover ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: isEditing || showHover)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(label.color.opacity(isEditing ? 0.10 : 0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing { beginEditingLabel(label) }
        }
        .onHover { isIn in
            if isIn { hoveredLabelId = label.id }
            else if hoveredLabelId == label.id { hoveredLabelId = nil }
        }
        .contextMenu {
            Button(L10n.edit) { beginEditingLabel(label) }
            Button(L10n.delete, role: .destructive) { requestDeleteLabel(label) }
        }
    }

    // MARK: - Label actions

    private func beginEditingLabel(_ label: TaskLabel) {
        // Auto-commit any pending rename on a different label before switching.
        if let inFlightId = editingLabelId, inFlightId != label.id,
           let inFlight = store.labels.first(where: { $0.id == inFlightId }) {
            commitLabel(inFlight)
        }
        labelName = label.name
        editingLabelId = label.id
    }

    /// Commits the in-progress label name to the store and exits edit mode.
    /// Color and icon are persisted live via their bindings, so the only
    /// field this commits is `name`. Trims whitespace; if the result is
    /// empty, falls back to the label's current name (so a stray Enter or
    /// empty checkmark doesn't blank the label).
    private func commitLabel(_ label: TaskLabel) {
        guard var fresh = store.labels.first(where: { $0.id == label.id }) else {
            editingLabelId = nil
            return
        }
        let trimmed = labelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = trimmed.isEmpty ? fresh.name : trimmed
        if newName != fresh.name {
            fresh.name = newName
            store.updateLabel(fresh)
        }
        editingLabelId = nil
    }

    /// Re-grabs focus on the label rename TextField after a popover (color
    /// or icon picker) dismisses, but only if the user is still editing
    /// this row.
    private func refocusLabelNameIfEditing(closingPopover: Bool, label: TaskLabel) {
        guard closingPopover, editingLabelId == label.id else { return }
        labelNameFocused = false
        DispatchQueue.main.async { labelNameFocused = true }
    }

    private func requestDeleteLabel(_ label: TaskLabel) {
        labelToDelete = label
        showLabelDeleteConfirm = true
    }

    /// Binding that reads/writes the chosen label's `colorHex` directly
    /// through the store. Mirrors `listColorBinding(for:)` so colour changes
    /// from the row swatch persist immediately, independent of the name
    /// edit form.
    private func labelColorBinding(for labelId: UUID) -> Binding<String> {
        Binding(
            get: {
                store.labels.first(where: { $0.id == labelId })?.colorHex
                    ?? ColorPalette.defaultHex
            },
            set: { newHex in
                guard var label = store.labels.first(where: { $0.id == labelId })
                else { return }
                label.colorHex = newHex
                store.updateLabel(label)
            }
        )
    }

    /// Binding that reads/writes the chosen label's `icon` directly
    /// through the store. Same shape as `labelColorBinding`.
    private func labelIconBinding(for labelId: UUID) -> Binding<String> {
        Binding(
            get: {
                store.labels.first(where: { $0.id == labelId })?.icon ?? IconPalette.defaultIcon
            },
            set: { newIcon in
                guard var label = store.labels.first(where: { $0.id == labelId })
                else { return }
                label.icon = newIcon
                store.updateLabel(label)
            }
        )
    }

    private func addNewLabel() {
        store.addLabel(name: L10n.newLabel, colorHex: ColorPalette.presets.randomElement()!.hex, icon: IconPalette.defaultIcon)
        let newLabel = store.labelsForActiveList.last!
        labelName = newLabel.name
        editingLabelId = newLabel.id
    }

    @State private var showClearConfirm = false

    private var dataSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.data).font(.body.weight(.medium))
                HStack(spacing: 8) {
                    actionButton(label: L10n.exportButton, icon: "arrow.up.doc", color: accent) {
                        let panel = NSSavePanel()
                        panel.allowedContentTypes = [.json]
                        panel.nameFieldStringValue = "docket-export.json"
                        if panel.runModal() == .OK, let url = panel.url {
                            let export = DocketExport(schemaVersion: Store.currentSchemaVersion, lists: store.lists, labels: store.labels, tasks: store.items)
                            try? JSONEncoder().encode(export).write(to: url, options: .atomic)
                        }
                    }
                    actionButton(label: L10n.importButton, icon: "arrow.down.doc", color: accent) {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.json]
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url,
                           let data = try? Data(contentsOf: url) {
                            if let export = try? JSONDecoder().decode(DocketExport.self, from: data) {
                                // Add lists that don't already exist (matched by name).
                                for list in export.lists where !store.lists.contains(where: { $0.name == list.name }) {
                                    store.lists.append(list)
                                }
                                for label in export.labels where !store.labels.contains(where: { $0.id == label.id }) {
                                    store.labels.append(label)
                                }
                                // Build maps to remap imported tasks onto surviving lists.
                                let exportedListName = Dictionary(export.lists.map { ($0.id, $0.name) },
                                                                   uniquingKeysWith: { first, _ in first })
                                let listIdByName = Dictionary(store.lists.map { ($0.name, $0.id) },
                                                              uniquingKeysWith: { first, _ in first })
                                let validListIds = Set(store.lists.map(\.id))
                                let defaultId = store.lists.first(where: { $0.isDefault })?.id ?? store.lists[0].id

                                for item in export.tasks where !store.items.contains(where: { $0.id == item.id }) {
                                    var item = item
                                    if let lid = item.listId, !validListIds.contains(lid) {
                                        // The referenced list was de-duplicated away — remap by
                                        // name, falling back to the default list.
                                        item.listId = exportedListName[lid].flatMap { listIdByName[$0] } ?? defaultId
                                    } else if item.listId == nil {
                                        item.listId = defaultId
                                    }
                                    store.items.append(item)
                                }
                                store.persistAll()
                            } else if let tasks = try? JSONDecoder().decode([TodoItem].self, from: data) {
                                for item in tasks where !store.items.contains(where: { $0.id == item.id }) {
                                    store.add(item)
                                }
                            }
                        }
                    }
                }
                Divider()
                actionButton(
                    label: L10n.clearCompleted,
                    icon: "trash",
                    color: .red,
                    badge: "\(store.completedTasks.count)"
                ) { showClearConfirm = true }
                .disabled(store.completedTasks.isEmpty)
                .opacity(store.completedTasks.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func actionButton(label: String, icon: String, color: Color, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.subheadline.weight(.medium))
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(color.opacity(0.2)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.4), lineWidth: 1))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Matrix Settings

    @AppStorage("matrixDoFirstColor") private var doFirstColor = "#EF4444"
    @AppStorage("matrixScheduleColor") private var scheduleColor = "#3B82F6"
    @AppStorage("matrixDelegateColor") private var delegateColor = "#F59E0B"
    @AppStorage("matrixEliminateColor") private var eliminateColor = "#64748B"
    @AppStorage("matrixDoFirstLabel") private var doFirstLabel = "Do First"
    @AppStorage("matrixScheduleLabel") private var scheduleLabel = "Schedule"
    @AppStorage("matrixDelegateLabel") private var delegateLabel = "Delegate"
    @AppStorage("matrixEliminateLabel") private var eliminateLabel = "Eliminate"
    @AppStorage("matrixLabelLength") private var matrixLabelLength = 14
    @AppStorage("matrixShowAxes") private var matrixShowAxes = true
    @AppStorage("matrixShowBadges") private var matrixShowBadges = true

    private var matrixSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.eisenhowerMatrix).font(.body.weight(.medium))

                // Quadrant colors + labels
                VStack(spacing: 8) {
                    matrixQuadrantRow(label: $doFirstLabel, color: $doFirstColor, defaultLabel: "Do First")
                    matrixQuadrantRow(label: $scheduleLabel, color: $scheduleColor, defaultLabel: "Schedule")
                    matrixQuadrantRow(label: $delegateLabel, color: $delegateColor, defaultLabel: "Delegate")
                    matrixQuadrantRow(label: $eliminateLabel, color: $eliminateColor, defaultLabel: "Eliminate")
                }

                Divider()

                // Label length
                HStack {
                    Text(L10n.labelLength).font(.subheadline)
                    Spacer()
                    Text(L10n.charsCount(matrixLabelLength)).font(.system(size: 11, weight: .medium)).foregroundStyle(accent)
                }
                Slider(value: Binding(get: { Double(matrixLabelLength) }, set: { matrixLabelLength = Int($0) }), in: 6...20, step: 1)
                    .tint(accent)

                Divider()

                // Toggles
                ThemedToggle(label: L10n.showAxisLabels, isOn: $matrixShowAxes)
                ThemedToggle(label: L10n.showCountBadges, isOn: $matrixShowBadges)

                Divider()

                HStack {
                    Text(L10n.labelLines).font(.subheadline)
                    Spacer()
                    Menu {
                        ForEach(1...5, id: \.self) { n in
                            Button("\(n)") { matrixLineCount = n }
                        }
                    } label: {
                        Text("\(matrixLineCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func matrixQuadrantRow(label: Binding<String>, color: Binding<String>, defaultLabel: String) -> some View {
        HStack(spacing: 10) {
            ColorSwatchButton(hex: color, popoverTitle: defaultLabel)
            TextField(defaultLabel, text: label)
                .textFieldStyle(.plain)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Visibility

    @AppStorage("showMatrixButton") private var showMatrixButton = true
    @AppStorage("showCompletedButton") private var showCompletedButton = true
    @AppStorage("matrixLineCount") private var matrixLineCount = 1

    private var displaySection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.display).font(.body.weight(.medium))
                ThemedToggle(label: L10n.liquidGlass, isOn: $useGlass)
                Divider()
                ThemedToggle(label: L10n.completionConfetti, isOn: $showConfetti)
                Divider()
                Text(L10n.showInToolbar).font(.caption).foregroundStyle(.secondary)
                ThemedToggle(label: L10n.matrixButton, isOn: $showMatrixButton)
                ThemedToggle(label: L10n.completedButton, isOn: $showCompletedButton)
            }
        }
    }

    private var themeSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.theme).font(.body.weight(.medium))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                    ForEach(AppTheme.allCases) { t in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { themeRaw = t.rawValue }
                        } label: {
                            VStack(spacing: 3) {
                                ZStack {
                                    if t == .custom {
                                        Circle().fill(AngularGradient(
                                            colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                            center: .center
                                        ))
                                    } else {
                                        Circle().fill(t.swatchColor)
                                    }
                                }
                                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 0.5))
                                .overlay(
                                    Circle().stroke(Color.accentColor, lineWidth: 2.5)
                                        .opacity(t.rawValue == themeRaw ? 1 : 0)
                                )
                                .frame(width: 28, height: 28)
                                Text(t.name)
                                    .font(.system(size: 9, weight: t.rawValue == themeRaw ? .semibold : .regular))
                                    .foregroundStyle(t.rawValue == themeRaw ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if themeRaw == AppTheme.custom.rawValue {
                    customSliders
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var customSliders: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L10n.color).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(Color(hue: customHue, saturation: customSat, brightness: 0.95))
                    .frame(width: 16, height: 16)
            }
            Slider(value: $customHue, in: 0...1)
                .tint(Color(hue: customHue, saturation: 0.7, brightness: 0.9))
            HStack {
                Text(L10n.intensity).font(.caption).foregroundStyle(.secondary)
                Slider(value: $customSat, in: 0.05...0.6)
                    .tint(Color(hue: customHue, saturation: customSat, brightness: 0.9))
            }
        }
    }

    // MARK: - Helpers

    private func setHotkey(_ code: Int, _ mods: Int) {
        hotkeyKeyCode = code
        hotkeyModifiers = mods
        AppDelegate.shared?.registerHotkey()
    }

    /// Small all-caps header that visually groups the cards beneath it.
    @ViewBuilder
    private func groupHeader(_ text: String, first: Bool = false) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, first ? 0 : 12)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(useGlass ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(ThemeManager.resolvedCardBackground(themeRaw: themeRaw)))
            )
            .overlay(useGlass ? nil : RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 0.5))
    }
}
