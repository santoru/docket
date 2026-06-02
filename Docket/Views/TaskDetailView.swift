// TaskDetailView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Edit view for an existing task with reminder settings.
struct TaskDetailView: View {
    @State var item: TodoItem
    @Binding var path: [NavDestination]
    @State private var hasDueDate = false
    @State private var hasRecurrence = false
    @State private var recurrenceFreq: Frequency = .weekly
    @State private var recurrenceInterval: Int = 1
    @State private var naturalDateText = ""
    @State private var parsedDatePreview: String? = nil
    @State private var originalItem: TodoItem?

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Title", text: $item.title)
                            .textFieldStyle(.plain)
                            .font(.title3.weight(.medium))
                        Rectangle().fill(accent.opacity(0.15)).frame(height: 1.5)
                    }

                    // Notes
                    TextField("Add notes...", text: $item.notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2...4)

                    // Priority + Labels
                    VStack(alignment: .leading, spacing: 14) {
                        PriorityPickerView(priority: $item.priority)
                        LabelPickerView(selectedIds: $item.labelIds)
                        QuadrantPickerView(quadrant: $item.quadrant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Due date
                    VStack(alignment: .leading, spacing: 10) {
                        ThemedToggle(label: "Due date", isOn: $hasDueDate, animated: true)
                        if hasDueDate {
                            // Natural language input
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundStyle(accent)
                                TextField("tomorrow 3pm, next friday...", text: $naturalDateText)
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .onSubmit { parseNaturalDate() }
                                    .onChange(of: naturalDateText) { _, _ in parseNaturalDate() }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(accent.opacity(0.05))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.15), lineWidth: 1))
                            )

                            if let parsed = parsedDatePreview {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right").font(.system(size: 9))
                                    Text(parsed).font(.caption)
                                }
                                .foregroundStyle(accent)
                                .padding(.leading, 4)
                            }

                            CalendarPickerView(selectedDate: Binding(
                                get: { item.dueDate ?? Date().addingTimeInterval(3600) },
                                set: { item.dueDate = $0 }
                            ))
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            TimePickerView(date: Binding(
                                get: { item.dueDate ?? Date().addingTimeInterval(3600) },
                                set: { item.dueDate = $0 }
                            ))
                            ReminderPickerView(offset: $item.reminderOffset)
                            RecurrencePickerView(hasRecurrence: $hasRecurrence, frequency: $recurrenceFreq, interval: $recurrenceInterval)
                        }
                    }

                    // Move to list
                    if Store.shared.lists.count > 1 {
                        HStack {
                            Text("List").font(.body)
                            Spacer()
                            Menu {
                                ForEach(Store.shared.lists) { list in
                                    Button(list.name) { item.listId = list.id }
                                }
                            } label: {
                                Text(Store.shared.lists.first(where: { $0.id == item.listId })?.name ?? "—")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(accent.opacity(0.12)))
                                    .foregroundStyle(accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Meta
                    HStack {
                        Text("Created").font(.caption).foregroundStyle(.tertiary)
                        Spacer()
                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.tertiary)
                    }

                    // Delete
                    Button {
                        Store.shared.delete(item)
                        path.removeLast()
                    } label: {
                        Text("Delete Task")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .onAppear {
            originalItem = item
            hasDueDate = item.dueDate != nil
            hasRecurrence = item.recurrence != nil
            recurrenceFreq = item.recurrence?.frequency ?? .weekly
            recurrenceInterval = item.recurrence?.interval ?? 1
        }
        .onChange(of: hasDueDate) { _, on in
            if !on { item.dueDate = nil }
            else if item.dueDate == nil { item.dueDate = Date().addingTimeInterval(3600) }
        }
    }

    private var header: some View {
        HStack {
            Button { cancelEdit() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.quaternary.opacity(0.5)))
            }.buttonStyle(.plain)
            Spacer()
            Text("Edit Task").font(.headline)
            Spacer()
            Button { confirmEdit() } label: { Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(.green).frame(width: 28, height: 28).background(Circle().fill(.quaternary.opacity(0.5))) }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func confirmEdit() {
        item.recurrence = hasDueDate && hasRecurrence ? Recurrence(frequency: recurrenceFreq, interval: recurrenceInterval, endDate: nil) : nil
        Store.shared.update(item)
        path.removeLast()
    }

    private func cancelEdit() {
        if let original = originalItem {
            Store.shared.update(original)
        }
        path.removeLast()
    }

    private func parseNaturalDate() {
        if let date = DateParser.parse(naturalDateText) {
            item.dueDate = date
            parsedDatePreview = date.formatted(date: .abbreviated, time: .shortened)
        } else {
            parsedDatePreview = nil
        }
    }
}
