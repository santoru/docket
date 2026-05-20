# Changelog

All notable changes to Docket will be documented in this file.

## [1.0.0] — 2026-05-20

### 🎉 Initial Release

#### Core
- Menu bar-only app with NSPopover (no Dock icon)
- Create, edit, complete, and delete tasks
- Priority levels: Low, Medium, High with pastel color-coded indicators
- Persistent JSON storage in `~/Library/Application Support/Docket/`
- Backward-compatible data model with custom Codable decoder

#### Multiple Lists
- Create, rename, and delete task lists
- "Default" list created on first launch (can rename, cannot delete)
- List switcher dropdown in header (hidden when only one list)
- Each list has its own tasks and labels

#### Labels
- Create labels with custom name, color (8 presets), and icon (15 SF Symbols)
- Attach multiple labels to any task
- Label picker in create/edit task views (multi-select pills)
- Labels displayed as colored pills on task cards
- Filter tasks by label via sort bar

#### Reminders & Notifications
- Optional due dates with custom-built calendar picker
- Custom themed time picker (hour/minute dropdowns)
- Configurable reminder offsets: at time, 5min, 10min, 30min, 1hr, 1 day before
- macOS native notifications via UserNotifications framework

#### Natural Language Dates
- Smart date parser: today, tomorrow, next [weekday], in X hours/days/weeks
- Additional patterns: noon, eod, later, this weekend, next week, midnight
- Live preview showing parsed result as you type
- NSDataDetector fallback for complex expressions

#### Interactions
- Swipe right to complete (green background reveal)
- Swipe left to delete (red background reveal)
- Tap anywhere on task card to open edit view
- Reorder mode with ▲/▼ buttons per task
- Confetti burst animation on task completion
- Undo toast with 3-second auto-dismiss

#### Sort & Filter
- Sort mode bar with pill toggle: Custom / By Due Date
- Custom mode: manual reorder with persistent sort order
- By Due Date mode: grouped sections (Overdue, Today, Upcoming, No date)
- Label filter pills in sort bar (second row)
- Sort preference persisted in UserDefaults

#### Search
- Animated search bar (slides in from header)
- Real-time filtering by title and notes
- Clear button and empty state

#### Global Keyboard Shortcut
- Default: ⌘⇧D to toggle popover from anywhere
- Quick-add: double-press shortcut to jump to new task form
- Configurable: 6 preset key combinations in Settings
- Enable/disable toggle

#### Keyboard Navigation
- ⌘N: new task (when popover is open)
- Esc: go back to previous view

#### Context Menu
- Right-click menu bar icon for quick actions
- Shows: New Task, overdue count, due-today count, GitHub link, Quit

#### Badge Count
- Menu bar icon shows number of overdue + due-today tasks
- Updates every 60 seconds and on popover close

#### Themes
- 9 built-in themes: White, Lavender, Rose, Peach, Lemon, Mint, Sky, Periwinkle, Night
- Custom theme with hue slider + intensity slider
- Theme-aware accent colors on all UI elements
- Dark mode support (Night theme)
- Liquid Glass mode (macOS 26) with toggle in Settings

#### Custom UI Components
- CalendarPickerView: themed month grid with accent-colored selection
- TimePickerView: hour/minute dropdown menus with accent pills
- ReminderPickerView: themed dropdown matching time picker style
- PriorityPickerView: colored capsule pills
- LabelPickerView: multi-select label pills with FlowLayout
- ThemedToggle: custom accent-colored switch
- ConfettiOverlay: particle burst animation
- SwipeableTaskRow: gesture-based swipe + reorder wrapper
- UndoToast: timed notification with undo action

#### Settings
- Default reminder offset
- Launch at login (SMAppService)
- Global shortcut enable/disable + key selection
- Lists management (create/rename/delete)
- Labels management (color + icon picker)
- Theme picker with custom color option
- Export/import all data as JSON
- Clear all completed tasks
- Version display + GitHub link

#### Onboarding
- Animated first-launch welcome screen
- 6 feature tips with staggered entrance
- "Get Started" button

#### Build System
- Single `build.sh` script — no Xcode.app required
- Compiles with `swiftc` + system frameworks
- Custom app icon (.icns) and menu bar template icon
- Zero external dependencies

---

[1.0.0]: https://github.com/santoru/docket/releases/tag/v1.0.0
