// CalendarPickerView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A custom themed calendar grid for selecting a date.
struct CalendarPickerView: View {
    @Binding var selectedDate: Date

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    @State private var displayedMonth: Date = Date()

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }
    private let calendar = Calendar.current
    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    /// All day slots for the displayed month (nil = blank leading cell).
    private var days: [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let weekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let blanks: [Date?] = Array(repeating: nil, count: weekday)
        let dates: [Date?] = range.map { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        return blanks + dates
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.medium)).foregroundStyle(accent)
                }.buttonStyle(.plain)
                Spacer()
                Text(monthTitle).font(.subheadline.weight(.semibold))
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right").font(.body.weight(.medium)).foregroundStyle(accent)
                }.buttonStyle(.plain)
            }

            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day).font(.system(size: 10, weight: .medium)).foregroundStyle(.tertiary)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayButton(for: date)
                    } else {
                        Text("").frame(width: 30, height: 30)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 0.5))
        .onAppear { displayedMonth = selectedDate }
    }

    // MARK: - Helpers

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                let time = calendar.dateComponents([.hour, .minute], from: selectedDate)
                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = time.hour
                comps.minute = time.minute
                selectedDate = calendar.date(from: comps) ?? date
            }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                .frame(width: 30, height: 30)
                .foregroundStyle(isSelected ? .white : isToday ? accent : .primary)
                .background(Circle().fill(isSelected ? accent : .clear))
                .overlay(
                    Circle().stroke(accent.opacity(0.4), lineWidth: 1.5)
                        .opacity(isToday && !isSelected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private func shiftMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
        }
    }
}
