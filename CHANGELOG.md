# Changelog

All notable changes to Docket will be documented in this file.

## [1.5.0] — 2026-05-25

### 🔄 Apple Reminders Integration
- Two-way sync with Apple Reminders via EventKit
- Auto-creates "Docket" list in Reminders (or links existing)
- Pick additional Reminders lists to sync into Docket
- Changes in Reminders (or via Siri/Apple Watch) pull back into Docket
- Conflict resolution: last-modified-date wins
- EKEventStoreChanged observer for reactive sync
- "Sync Now" button and last sync timestamp

### 📝 README
- Added Reminders integration section
- Updated architecture, tech stack, and permissions

---

## [1.4.0] — 2026-05-25

### 🔁 Recurring Tasks
- Daily, weekly, monthly repeat with configurable interval (1–10)
- Auto-creates next task instance on completion
- RecurrencePickerView in create/edit views
- Frequency label shown on task cards ("Weekly", "Every 2 weeks")

### 🎨 UI Improvements
- Redesigned Export/Import/Clear as outlined action buttons
- Confirmation dialog for clearing completed tasks
- Multi-line task title setting (toggle in Settings)
- Theme grid fixed to 5 columns (was overflowing to 3 rows)
- Recurrence indicator with text label on task cards

---

## [1.3.1] — 2026-05-23

### 🐛 Fixes
- Retina menu bar icon: load @2x image with correct display size

---

## [1.3.0] — 2026-05-22

### 🔁 Recurring Tasks (initial)
- Recurrence model (Frequency + interval + end date)
- Store spawns next instance on complete
- Theme grid fix (5 columns)

### 🐛 Fixes
- Notification permission: codesign app with bundle ID
- Notification delegate for foreground banner delivery
- Delayed permission request for proper initialization

---

## [1.2.0] — 2026-05-21

### 📋 Features
- Move task to another list (picker in edit view)
- Badge scope setting: count current list only or all lists
- Delete list confirmation when list has tasks
- Navigation: back arrow (←) + checkmark (✓) on all sub-screens

### 🎨 UI
- Consistent materials (search bar, undo toast, calendar arrows)
- Completed view shows task count in header
- Tappable empty state ("Add your first task")
- Updated onboarding tips (mentions lists, labels, sort)
- Unified × close buttons across all views
- TaskDetailView redesigned to match CreateTaskView style
- Standardized 20px content padding
- ZStack centered title in CreateTaskView header

---

## [1.1.0] — 2026-05-21

### 🔔 Notifications
- Notification sound picker (Default, Ping, Glass, Pop, Purr, Submarine, Tink, None)
- Sound preview on selection
- Sound setting grouped with default reminder

### 🎨 UI
- Red circle badge on menu bar icon for overdue/due-today count
- Softer pastel priority colors (dusty blue, warm amber, muted coral)

---

## [1.0.0] — 2026-05-20

### 🎉 Initial Release

#### Core
- Menu bar-only app with NSPopover (no Dock icon)
- Create, edit, complete, and delete tasks
- Priority levels: Low, Medium, High with color-coded indicators
- Persistent JSON storage
- Backward-compatible data model

#### Multiple Lists
- Create, rename, and delete task lists
- List switcher dropdown (hidden when only one list)
- Each list has its own tasks and labels

#### Labels
- Create labels with custom name, color (8 presets), and icon (15 SF Symbols)
- Multi-select label picker in create/edit views
- Labels displayed on task cards
- Filter tasks by label in sort bar

#### Reminders & Notifications
- Optional due dates with custom calendar picker
- Custom time picker
- Configurable reminder offsets (5min → 1 day)
- macOS native notifications

#### Natural Language Dates
- Smart parser: today, tomorrow, next weekday, in X hours/days/weeks
- Additional: noon, eod, later, weekend, midnight, this afternoon
- Live preview as you type

#### Interactions
- Swipe right → complete, left → delete
- Reorder mode with ▲/▼ buttons
- Confetti on completion
- Undo toast (3s auto-dismiss)

#### Sort & Filter
- Custom order or By Due Date (grouped sections)
- Label filter pills
- Animated search bar

#### Keyboard & Shortcuts
- Global hotkey (⌘⇧D, configurable)
- Quick-add (double-press)
- ⌘N new task, Esc go back
- Right-click context menu

#### Themes
- 9 built-in + custom color picker
- Liquid Glass mode (macOS 26)
- Dark mode (Night theme)
- Accent-colored UI throughout

#### Custom Components
- CalendarPickerView, TimePickerView, ReminderPickerView
- PriorityPickerView, LabelPickerView, ThemedToggle
- ConfettiOverlay, UndoToast, SwipeableTaskRow

#### Settings
- Default reminder, launch at login, global shortcut
- Lists/labels management, theme picker
- Export/import JSON, clear completed
- Version + GitHub link

#### Build
- Single build.sh script, zero dependencies
- Custom app icon (.icns) and menu bar template icon
- Codesigned with bundle ID

---

[1.5.0]: https://github.com/santoru/docket/releases/tag/v1.5.0
[1.4.0]: https://github.com/santoru/docket/releases/tag/v1.4.0
[1.3.1]: https://github.com/santoru/docket/releases/tag/v1.3.1
[1.3.0]: https://github.com/santoru/docket/releases/tag/v1.3.0
[1.2.0]: https://github.com/santoru/docket/releases/tag/v1.2.0
[1.1.0]: https://github.com/santoru/docket/releases/tag/v1.1.0
[1.0.0]: https://github.com/santoru/docket/releases/tag/v1.0.0

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

[1.5.0]: https://github.com/santoru/docket/releases/tag/v1.5.0
[1.0.0]: https://github.com/santoru/docket/releases/tag/v1.0.0
