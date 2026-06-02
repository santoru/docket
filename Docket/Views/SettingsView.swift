// SettingsView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit
import EventKit
import ServiceManagement
import Carbon.HIToolbox

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
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    reminderSection
                    launchSection
                    hotkeySection
                    remindersSection
                    listsSection
                    labelsSection
                    matrixSection
                    visibilitySection
                    themeSection
                    exportImportSection
                    clearSection

                    VStack(spacing: 4) {
                        Text("Docket v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                            .font(.caption).foregroundStyle(.tertiary)
                        Link("github.com/santoru/docket", destination: URL(string: "https://github.com/santoru/docket")!)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .alert("Delete List", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let list = listToDelete { withAnimation { store.deleteList(list) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let list = listToDelete {
                let count = store.items.filter { $0.listId == list.id }.count
                Text("\"\(list.name)\" has \(count) task\(count == 1 ? "" : "s"). They will be moved to the default list.")
            }
        }
        .alert("Clear Completed", isPresented: $showClearConfirm) {
            Button("Clear \(store.completedTasks.count) tasks", role: .destructive) {
                withAnimation { store.clearCompleted() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all completed tasks.")
        }
    }

    private var header: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(Circle().fill(.quaternary.opacity(0.5)))
            }.buttonStyle(.plain)
            Spacer()
            Text("Settings").font(.headline)
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
                Text("Notifications").font(.body.weight(.medium))
                HStack {
                    Text("Default reminder").font(.subheadline)
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
                    Text("Sound").font(.subheadline)
                    Spacer()
                    Menu {
                        Button("Default") { setSound("default") }
                        Button("Ping") { setSound("Ping") }
                        Button("Glass") { setSound("Glass") }
                        Button("Pop") { setSound("Pop") }
                        Button("Purr") { setSound("Purr") }
                        Button("Submarine") { setSound("Submarine") }
                        Button("Tink") { setSound("Tink") }
                        Button("None") { setSound("none") }
                    } label: {
                        Text(notifSound == "default" ? "Default" : notifSound == "none" ? "None" : notifSound)
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
                    Text("Badge counts").font(.subheadline)
                    Spacer()
                    Menu {
                        Button("Current list") { badgeAllLists = false }
                        Button("All lists") { badgeAllLists = true }
                    } label: {
                        Text(badgeAllLists ? "All lists" : "Current list")
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

    private var launchSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("General").font(.body.weight(.medium))
                ThemedToggle(label: "Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        if on { try? SMAppService.mainApp.register() }
                        else { SMAppService.mainApp.unregister { _ in } }
                    }
                Divider()
                ThemedToggle(label: "Liquid Glass", isOn: $useGlass)
                Divider()
                ThemedToggle(label: "Multi-line tasks", isOn: $multiLineTask)
            }
        }
    }

    private var hotkeySection: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Keyboard").font(.body.weight(.medium))
                ThemedToggle(label: "Global shortcut", isOn: $hotkeyEnabled)
                    .onChange(of: hotkeyEnabled) { _, _ in AppDelegate.shared?.registerHotkey() }
                if hotkeyEnabled {
                    HStack {
                        Text("Shortcut").font(.subheadline)
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
                ThemedToggle(label: "Sync with Reminders", isOn: $remindersSyncEnabled)
                    .onChange(of: remindersSyncEnabled) { _, on in
                        if on { enableSync() } else { disableSync() }
                    }

                if remindersSyncEnabled {
                    if availableCalendars.isEmpty {
                        Text("No access to Reminders").font(.caption).foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lists to sync").font(.caption).foregroundStyle(.secondary)
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
                            Text("Last sync: \(lastSync, style: .relative) ago")
                                .font(.caption).foregroundStyle(.tertiary)
                        }

                        Button { RemindersSync.shared.syncAll() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath").font(.caption)
                                Text("Sync Now").font(.caption.weight(.medium))
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
                store.saveLists()
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

    private var listsSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Lists").font(.body.weight(.medium))
                    Spacer()
                    Button {
                        store.addList(name: "New List")
                        editingName = "New List"
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
                            Circle()
                                .fill(list.id == store.activeListId ? accent : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)

                            if editingListId == list.id {
                                TextField("Name", text: $editingName, onCommit: {
                                    store.renameList(list, to: editingName)
                                    editingListId = nil
                                })
                                .textFieldStyle(.plain)
                                .font(.body)
                                Spacer()
                                Button {
                                    store.renameList(list, to: editingName)
                                    editingListId = nil
                                } label: {
                                    Text("Done").font(.caption.weight(.semibold)).foregroundStyle(accent)
                                }.buttonStyle(.plain)
                            } else {
                                Text(list.name)
                                    .font(.body)
                                    .foregroundStyle(list.id == store.activeListId ? .primary : .secondary)
                                Spacer()
                                HStack(spacing: 12) {
                                    Button {
                                        editingName = list.name
                                        editingListId = list.id
                                    } label: {
                                        Image(systemName: "pencil.line")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }.buttonStyle(.plain)

                                    if !list.isDefault {
                                        Button {
                                            let taskCount = store.items.filter { $0.listId == list.id }.count
                                            if taskCount > 0 {
                                                listToDelete = list
                                                showDeleteConfirm = true
                                            } else {
                                                withAnimation { store.deleteList(list) }
                                            }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                        }.buttonStyle(.plain)
                                    }
                                }
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
                    }
                }
            }
        }
    }

    // MARK: - Labels Settings

    @State private var editingLabelId: UUID?
    @State private var labelName = ""
    @State private var labelColor = TaskLabel.presetColors[5].hex
    @State private var labelIcon = "tag"

    private var labelsSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Labels").font(.body.weight(.medium))
                    Spacer()
                    Button { addNewLabel() } label: {
                        Image(systemName: "plus").font(.body.weight(.medium)).foregroundStyle(accent)
                    }.buttonStyle(.plain)
                }

                if store.labelsForActiveList.isEmpty {
                    Text("No labels yet").font(.caption).foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 4) {
                        ForEach(store.labelsForActiveList) { label in
                            if editingLabelId == label.id {
                                labelEditRow(label: label)
                            } else {
                                labelDisplayRow(label: label)
                            }
                        }
                    }
                }
            }
        }
    }

    private func labelDisplayRow(label: TaskLabel) -> some View {
        HStack(spacing: 10) {
            Circle().fill(label.color).frame(width: 10, height: 10)
            Image(systemName: label.icon).font(.system(size: 11)).foregroundStyle(label.color)
            Text(label.name).font(.subheadline)
            Spacer()
            Button {
                labelName = label.name
                labelColor = label.colorHex
                labelIcon = label.icon
                editingLabelId = label.id
            } label: {
                Image(systemName: "pencil.line").font(.system(size: 13)).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            Button { withAnimation { store.deleteLabel(label) } } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(label.color.opacity(0.05)))
    }

    private func labelEditRow(label: TaskLabel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Name", text: $labelName)
                .textFieldStyle(.plain).font(.caption)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary.opacity(0.5)))
            HStack(spacing: 4) {
                ForEach(TaskLabel.presetColors, id: \.hex) { preset in
                    Button { labelColor = preset.hex } label: {
                        Circle().fill(Color(hex: preset.hex))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white, lineWidth: labelColor == preset.hex ? 2 : 0))
                    }.buttonStyle(.plain)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(TaskLabel.presetIcons, id: \.self) { icon in
                    Button { labelIcon = icon } label: {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                            .background(RoundedRectangle(cornerRadius: 6).fill(labelIcon == icon ? Color(hex: labelColor).opacity(0.2) : Color.clear))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(labelIcon == icon ? Color(hex: labelColor) : Color.clear, lineWidth: 1))
                            .foregroundStyle(labelIcon == icon ? Color(hex: labelColor) : .secondary)
                    }.buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button {
                    var updated = label
                    updated.name = labelName
                    updated.colorHex = labelColor
                    updated.icon = labelIcon
                    store.updateLabel(updated)
                    editingLabelId = nil
                } label: {
                    Text("Done").font(.caption.weight(.semibold)).foregroundStyle(accent)
                }.buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.2)))
    }

    private func addNewLabel() {
        store.addLabel(name: "New Label", colorHex: TaskLabel.presetColors.randomElement()!.hex, icon: "tag")
        let newLabel = store.labelsForActiveList.last!
        labelName = newLabel.name
        labelColor = newLabel.colorHex
        labelIcon = newLabel.icon
        editingLabelId = newLabel.id
    }

    @State private var showClearConfirm = false

    private var clearSection: some View {
        VStack(spacing: 8) {
            actionButton(
                label: "Clear completed",
                icon: "trash",
                color: .red,
                badge: "\(store.completedTasks.count)"
            ) { showClearConfirm = true }
            .disabled(store.completedTasks.isEmpty)
            .opacity(store.completedTasks.isEmpty ? 0.5 : 1)
        }
    }

    private var exportImportSection: some View {
        HStack(spacing: 8) {
            actionButton(label: "Export", icon: "arrow.up.doc", color: accent) {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "docket-export.json"
                if panel.runModal() == .OK, let url = panel.url {
                    let export = DocketExport(lists: store.lists, labels: store.labels, tasks: store.items)
                    try? JSONEncoder().encode(export).write(to: url, options: .atomic)
                }
            }
            actionButton(label: "Import", icon: "arrow.down.doc", color: accent) {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url,
                   let data = try? Data(contentsOf: url) {
                    if let export = try? JSONDecoder().decode(DocketExport.self, from: data) {
                        for list in export.lists where !store.lists.contains(where: { $0.name == list.name }) {
                            store.lists.append(list)
                        }
                        for label in export.labels where !store.labels.contains(where: { $0.id == label.id }) {
                            store.labels.append(label)
                        }
                        for item in export.tasks where !store.items.contains(where: { $0.id == item.id }) {
                            store.items.append(item)
                        }
                    } else if let tasks = try? JSONDecoder().decode([TodoItem].self, from: data) {
                        for item in tasks where !store.items.contains(where: { $0.id == item.id }) {
                            store.add(item)
                        }
                    }
                }
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
    @AppStorage("matrixEliminateColor") private var eliminateColor = "#9CA3AF"
    @AppStorage("matrixDoFirstLabel") private var doFirstLabel = "Do First"
    @AppStorage("matrixScheduleLabel") private var scheduleLabel = "Schedule"
    @AppStorage("matrixDelegateLabel") private var delegateLabel = "Delegate"
    @AppStorage("matrixEliminateLabel") private var eliminateLabel = "Eliminate"
    @AppStorage("matrixLabelLength") private var matrixLabelLength = 14
    @AppStorage("matrixShowAxes") private var matrixShowAxes = true
    @AppStorage("matrixShowBadges") private var matrixShowBadges = true

    private let matrixColorPresets = ["#EF4444", "#F59E0B", "#10B981", "#3B82F6", "#8B5CF6", "#EC4899", "#6B7280", "#14B8A6"]

    private var matrixSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Eisenhower Matrix").font(.body.weight(.medium))

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
                    Text("Label length").font(.subheadline)
                    Spacer()
                    Text("\(matrixLabelLength) chars").font(.system(size: 11, weight: .medium)).foregroundStyle(accent)
                }
                Slider(value: Binding(get: { Double(matrixLabelLength) }, set: { matrixLabelLength = Int($0) }), in: 6...20, step: 1)
                    .tint(accent)

                Divider()

                // Toggles
                ThemedToggle(label: "Show axis labels", isOn: $matrixShowAxes)
                ThemedToggle(label: "Show count badges", isOn: $matrixShowBadges)
            }
        }
    }

    private func matrixQuadrantRow(label: Binding<String>, color: Binding<String>, defaultLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Editable label
                TextField(defaultLabel, text: label)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                Spacer()
            }
            HStack(spacing: 5) {
                ForEach(matrixColorPresets, id: \.self) { hex in
                    Button { color.wrappedValue = hex } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white, lineWidth: color.wrappedValue == hex ? 2 : 0))
                            .overlay(Circle().stroke(Color(hex: hex).opacity(0.5), lineWidth: color.wrappedValue == hex ? 1 : 0).scaleEffect(1.3))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Visibility

    @AppStorage("showMatrixButton") private var showMatrixButton = true
    @AppStorage("showCompletedButton") private var showCompletedButton = true

    private var visibilitySection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Show in toolbar").font(.body.weight(.medium))
                ThemedToggle(label: "Matrix button", isOn: $showMatrixButton)
                ThemedToggle(label: "Completed button", isOn: $showCompletedButton)
            }
        }
    }

    private var themeSection: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Theme").font(.body.weight(.medium))
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
                Text("Color").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(Color(hue: customHue, saturation: customSat, brightness: 0.95))
                    .frame(width: 16, height: 16)
            }
            Slider(value: $customHue, in: 0...1)
                .tint(Color(hue: customHue, saturation: 0.7, brightness: 0.9))
            HStack {
                Text("Intensity").font(.caption).foregroundStyle(.secondary)
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

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(useGlass ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.white.opacity(0.65)))
            )
            .overlay(useGlass ? nil : RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 0.5))
    }
}
