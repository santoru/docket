// CreateTaskView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Form for creating a new task with optional due date and reminder.
struct CreateTaskView: View {
    @Binding var path: [NavDestination]

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: Priority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var reminderOffset: ReminderOffset = .tenMinutes
    @State private var naturalDateText = ""
    @State private var parsedDatePreview: String? = nil
    @State private var selectedLabelIds: [UUID] = []
    @State private var selectedQuadrant: Quadrant? = nil
    @State private var hasRecurrence = false
    @State private var recurrenceFreq: Frequency = .weekly
    @State private var recurrenceInterval: Int = 1
    @FocusState private var titleFocused: Bool

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    // Title - prominent, large
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("What needs to be done?", text: $title)
                            .textFieldStyle(.plain)
                            .font(.title3.weight(.medium))
                            .focused($titleFocused)
                        Rectangle()
                            .fill(accent.opacity(titleFocused ? 0.6 : 0.15))
                            .frame(height: 1.5)
                            .animation(.easeInOut(duration: 0.2), value: titleFocused)
                    }

                    // Notes - subtle
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2...4)

                    // Priority + Labels
                    VStack(alignment: .leading, spacing: 14) {
                        PriorityPickerView(priority: $priority)
                        LabelPickerView(selectedIds: $selectedLabelIds)
                        QuadrantPickerView(quadrant: $selectedQuadrant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Due date section
                    VStack(alignment: .leading, spacing: 10) {
                        ThemedToggle(label: "Due date", isOn: $hasDueDate, animated: true)

                        if hasDueDate {
                            // Smart date input
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

                            CalendarPickerView(selectedDate: $dueDate)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            TimePickerView(date: $dueDate)
                            ReminderPickerView(offset: $reminderOffset)
                            RecurrencePickerView(hasRecurrence: $hasRecurrence, frequency: $recurrenceFreq, interval: $recurrenceInterval)
                        }
                    }
                }
                .padding(20)
            }
        }
        .onAppear { titleFocused = true }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("New Task").font(.headline)
            HStack {
                Button { path.removeLast() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(.quaternary.opacity(0.5)))
                }.buttonStyle(.plain)
                Spacer()
                Button {
                    Store.shared.add(TodoItem(
                        title: title, notes: notes, priority: priority,
                        dueDate: hasDueDate ? dueDate : nil, reminderOffset: reminderOffset,
                        labelIds: selectedLabelIds,
                        recurrence: hasDueDate && hasRecurrence ? Recurrence(frequency: recurrenceFreq, interval: recurrenceInterval, endDate: nil) : nil
                    ))
                    path.removeLast()
                } label: {
                    Text("Add Task")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(title.isEmpty ? Color.gray.opacity(0.3) : accent))
                        .foregroundStyle(title.isEmpty ? Color.gray : Color.white)
                }
                .buttonStyle(.plain)
                .disabled(title.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func parseNaturalDate() {
        if let date = DateParser.parse(naturalDateText) {
            dueDate = date
            parsedDatePreview = date.formatted(date: .abbreviated, time: .shortened)
        } else {
            parsedDatePreview = nil
        }
    }
}
