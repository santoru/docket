# Changelog

All notable changes to Docket will be documented in this file.

## [1.11.1] — 2026-06-15

### 🐛 Fixes
- **The complete-circle button on a task card works again.** The drag-to-reorder work had attached a high-priority tap to the whole row, which swallowed taps before they reached the button. The row tap is now a normal gesture, so the button (and tap-to-open, swipe, and long-press reorder) all behave correctly.

---

## [1.11.0] — 2026-06-10

### 🌍 Localization
- **Docket now speaks English and Italian.** Every user-facing string — task list, create/edit, settings, the Eisenhower matrix, onboarding, pickers, the menu-bar menu, alerts, and notifications — is fully localized and follows your system language.
- All strings route through a single `L10n` catalog backed by `en` / `it` `Localizable.strings` tables; the app declares `CFBundleLocalizations` for English and Italian.
- Not translated by design: your own list/label/task names, macOS system sound names, keyboard-shortcut symbols, the editable matrix quadrant labels, and the (English-only) smart-date keywords.

To preview a language without changing your system setting: `open Docket.app --args -AppleLanguages '(it)'`.

---

## [1.10.0] — 2026-06-10

### ✨ Drag to Reorder
- **Long-press a task and drag to reorder it.** After a brief hold (0.18s) the card grows in place to signal it's grabbed, then floats under the cursor while the other tasks part to make room; release to drop. Replaces the old ▲/▼ reorder arrows.
- **Works in every sort mode.** In *By Due Date* or *By Priority*, starting a drag adopts the currently-visible order as your Custom order and switches to Custom (with a brief "Switched to Custom order" toast) so the drag continues seamlessly.
- **Edge auto-scroll** — drag near the top/bottom of a long list to scroll while dragging.
- A quick click still opens the task; a horizontal swipe still completes/deletes.
- VoiceOver **Move up / Move down** actions as an accessible fallback.

### ✨ Sorting
- New **By Priority** sort mode (High / Medium / Low groups), alongside Custom and By Due Date.

### 🧹 Under the hood
- The lifted card is a floating overlay that tracks the cursor (pure translation); the real row stays as an invisible placeholder so rows part live around the insertion point.
- The task list uses an eager `VStack` so every row is measured correctly even when scrolled.

---

## [1.9.0] — 2026-06-10

### ✨ Settings
- **Reorganized Settings into five labeled groups** — General, Appearance, Notifications, Organize, Sync & Data — with consistent card titles. Appearance controls are consolidated into one **Display** card, and Export / Import / Clear are merged into a single **Data** card. No stored preferences changed.

---

## [1.8.0] — 2026-06-10

### 🐛 Fixes
- **Import now persists** and remaps orphaned task lists — imported backups no longer vanish on relaunch.
- **Recurring tasks no longer duplicate** when Reminders sync is on (Docket owns recurrence; no `EKRecurrenceRule` is pushed).
- The global hotkey handler is installed once instead of stacking across shortcut changes.
- The local key monitor is removed on close instead of accumulating across popover reopens.
- Reorder controls hidden while searching; added a **No results** state.
- Reminders sync moved off the main thread and no longer self-triggers a sync loop.

### ✨ Improvements
- Data **schema versioning** + migration scaffold; `os.Logger` on all persistence with surfaced failures.
- Hardened `Color(hex:)`, centralized priority colors, human accessibility labels on toolbar buttons.
- Added a dependency-free unit test suite (`./run-tests.sh`).
- **Completion confetti toggle** in Settings.

---

## [1.7.10] — 2026-06-04

### ✨ Matrix UX
- **Drop zone background also fades in when items are already in Unassigned.** Previously the dashed-outline drop zone only appeared in the empty state. Now it surfaces behind the populated pill strip too, so the affordance is consistent regardless of whether any tasks are parked there.
- Extracted `dropZoneBackground` as a shared view so both states use the same visual language.

---

## [1.7.9] — 2026-06-04

### ✨ Matrix UX
- **Unassigned drop zone fades in/out** instead of sliding from the top edge — calmer, less distracting transition.

---

## [1.7.8] — 2026-06-04

### ✨ Matrix UX
- **Top-row → Unassigned now works.** Dragging a pill from `Do First` or `Schedule` past the bottom of the *whole* grid now drops it into Unassigned. Previously the cross-over check fired on the first crossed edge — going down past `bounds.height` already mapped to the bottom-row neighbour, so the pill never reached the "below grid" check. Threshold is now `2 × rowHeight + spacing + 30pt` for top-row sources, `rowHeight + 30pt` for bottom-row sources.
- **Unassigned drop zone is now a contextual affordance.** When the strip is empty it stays hidden, exactly like before 1.7.5. As soon as the user picks up a quadrant pill, the empty drop zone fades + slides in from the top edge so the destination is clearly marked. It hides again when the drag ends.

### 🧹 Cleanups
- New `@State isAnyPillDragging` on `MatrixView`, bound into each `TaskDot` — surfaces the gesture state to the matrix without coupling individual pills together.

---

## [1.7.7] — 2026-06-04

### 🐛 Fixes
- **Diagonal drags now land in the diagonal target.** A flick from `Do First` (top-left) toward `Eliminate` (bottom-right) crossed both the right and bottom edges, but the cross-over switch used ternary precedence and matched the right edge first, so the pill ended up in `Schedule`. Detection now checks both axes and recognises the four diagonal cases:
  - `Do First` → `Eliminate` (right + bottom)
  - `Schedule` → `Delegate` (left + bottom)
  - `Delegate` → `Schedule` (right + top)
  - `Eliminate` → `Do First` (left + top)
- **Diagonal landings sit in the corner of the target closest to the source**, not in its centre — so the pill feels like it travelled diagonally across the boundary instead of teleporting.

---

## [1.7.6] — 2026-06-04

### 🐛 Fixes
- **Cross-quadrant moves no longer "drop from the top".** When a pill was dragged into a different quadrant, the source `TaskDot` was destroyed and a new one was created in the target. The new view's `@State position` defaults to `.zero` (the top-left of the quadrant), and `onAppear`'s `seedPosition()` was running inside the still-active `withAnimation(.spring)` transaction wrapping the store mutate — so SwiftUI animated the pill in from `(0, 0)`.
- Removed the `withAnimation` wrapper around the four cross-container mutations (cross-quadrant from `handleDragEnd`, drop-to-Unassigned from `handleDragEnd`, `quadrantBox.dropDestination`, `unassignedSection.dropDestination`). The move is now instant — the pill simply appears at its destination.
- Hardened `onAppear` with `Transaction(animation: nil)` so any future caller that wraps a mutation in `withAnimation` still gets a clean entry.

---

## [1.7.5] — 2026-06-04

### ✨ Matrix UX
- **Unassigned area is always visible.** Now that quadrant pills can be dropped onto it to clear their assignment, the strip is shown even when no tasks live there. The empty state renders a dashed-outline drop zone with a "Drag a pill here to remove it from the matrix" hint, so the affordance is discoverable.
- The drop destination is active in both empty and populated states.

---

## [1.7.4] — 2026-06-04

### 🐛 Fixes
- **Drag tracking is now precise.** The pill's `position` is updated directly during drag instead of via a separate `dragOffset`; the `.animation(_:value:)` modifier was reordered to sit *before* `.position(...)` in the chain so cursor-following updates aren't subjected to a spring. This eliminates the "drops from the top" feel where the pill appeared to snap back to its origin and then spring to the cursor.
- **Quick flicks now cross quadrants reliably.** Cross-over detection uses `value.predictedEndTranslation` (which accounts for gesture momentum) instead of the raw release translation, so a fast flick that physically stops just shy of the boundary still lands in the intended target quadrant.
- **In-quadrant settle uses `.smooth` instead of `.spring`** — critically damped easing, no overshoot, the pill simply eases into its resting place.
- **Diagonal-exit drags now settle gracefully** instead of staying stuck at the cursor: if the predicted endpoint exits the source bounds but doesn't map to any neighbour, the pill is clamped back inside via `settleInside(...)`.
- **Tap detection threshold raised to 3pt of motion before a drag begins**, so a still click can no longer trigger a brief scale-up flicker.

---

## [1.7.3] — 2026-06-04

### ✨ Matrix UX
- **Drag a pill across boundaries with intent preserved.** Cross-quadrant drags now translate the exit-edge crossing into the target quadrant — vertical position is kept on left/right transitions and horizontal position on top/bottom transitions, instead of teleporting to the centre.
- **Cross-quadrant moves animate.** Pills spring into their new spot rather than snapping.
- **Drag a bottom-row pill out the bottom of the matrix to un-assign it.** Returns the task to the Unassigned strip without opening the detail view.
- **Unassigned strip is now a drop target.** Drag a pill onto it from any quadrant to clear its assignment.
- **Empty quadrants show a subtle "Drop tasks here" hint** in the quadrant tint.
- **Marquee paused while dragging** — the title no longer scrolls under the cursor while you reposition a pill.

### 🐛 Fixes
- **Pills now re-seat when bounds or settings change.** `onChange(of: initialPosition)` springs each pill to its new computed spot when the window is resized or `Label length` / `Label lines` are adjusted in Settings — previously they stayed pinned to their old absolute coordinates.
- **Anti-collision uses real rectangles.** Switched from a centre-to-centre 38pt distance check to bounding-box intersection (with a 2pt inflation pad), so multi-line pills can no longer visually touch.
- **Tap-vs-drag disambiguation.** A drag with total max distance under 4pt is now treated as a tap, so wiggling the cursor while clicking no longer steals the gesture from the detail-view tap target.

### 🧹 Cleanups
- **`Store.mutate(id:_:)`** centralises the "find item → mutate → persist" pattern. All three matrix call sites now go through it instead of indexing into `store.items` directly.
- **`matrixLineCount` has a single source of truth.** Removed the duplicate `@AppStorage` from `TaskDot` — it's now passed in from the parent.
- **`initialPosition` is `CGPoint?`** instead of using `.zero` as a magic "not yet computed" sentinel.

---

## [1.7.2] — 2026-06-03

### 🐛 Fixes
- Matrix pills now stay fully inside the quadrant border. Previously the position clamp used a small fixed inset (~30pt) instead of the actual pill geometry, so half a pill (~52pt at default settings) could stick outside the box. Both the anti-collision resolver and the drag-end persister now compute clamps from the real pill width/height
- Pill text width is also capped to the available container, so long label-length settings can no longer make a single pill wider than its quadrant

---

## [1.7.1] — 2026-06-03

### ✨ Matrix Pill Marquee
- Hover a truncated task pill in the Eisenhower Matrix to smoothly scroll the title and reveal the rest of the text
- Linear, autoreversing animation at a constant 28pt/sec — long titles take proportionally longer
- Brief 0.25s pause before the first slide, eases back to the resting `…` ellipsis on hover-out
- Pills that already fit get no animation (overflow detected via a hidden measurer)
- Single-line mode only; multi-line pills retain the native truncation behaviour

---

## [1.7.0] — 2026-06-03

### 📊 Eisenhower Matrix Redesign
- Refined, more professional and minimal aesthetic — quieter tinted fills, hairline borders, continuous-corner shapes
- Quadrant headers use small-caps tracked typography (`DO FIRST` / `SCHEDULE` / …) next to a tighter SF Symbol
- Count badges restyled as minimal tinted capsules with monospaced digits
- Axis labels (`URGENT` / `IMPORTANT` / …) refined with proper letter-spacing and tertiary foreground
- Task pills converted from `Capsule` to `RoundedRectangle` with hairline coloured borders and a much subtler shadow
- Soft hover effect on pills, focused/dragged pills lift to the top via `zIndex`

### ✂️ Native Truncation on Pill Labels
- Long titles now truncate with a real `…` ellipsis instead of being hard-cut by `String.prefix`
- Width budget derived from the existing **Label length** setting; respects 1–5 line counts
- Same treatment applied to the Unassigned strip

### 🧲 Anti-Collision for Pill Positioning
- New per-quadrant resolver: when two tasks are stored at (or dragged onto) the same point, the second pill spirals outward by a small delta until it clears every previously placed pill
- Pills can no longer fully overlap inside a quadrant
- Stable, deterministic layout across renders; the user's original drop point is still persisted — only the *visual* position is nudged when needed

---

## [1.6.1] — 2026-06-03

### 🐛 Fixes
- Scroll bars now use the auto-hiding overlay style instead of the persistent legacy scroller (shown when a mouse is attached)

## [1.6.0] — 2026-06-03

### 📊 Eisenhower Matrix
- Visual 2×2 matrix view with free-positioned task pills
- Drag tasks within quadrants to express relative priority
- Drag tasks across quadrant boundaries to re-categorize
- Drag unassigned tasks from bottom into quadrants
- Quadrant picker in create/edit task views
- Customizable quadrant colors (8 presets per quadrant)
- Customizable quadrant labels (rename Do First/Schedule/etc)
- Configurable label length and line count (1–5 lines)
- Toggle axis labels (URGENT/IMPORTANT)
- Toggle count badges per quadrant
- Grid button in toolbar (hideable via Settings)

### ✏️ Edit Task Improvements
- × Cancel (restores original) / ✓ Confirm (saves changes) semantics
- Natural language date input in edit view (same as create)
- Divider below header (matches other views)

### 🎛️ Settings
- "Show in toolbar" section: hide/show Matrix and Completed buttons
- Eisenhower Matrix settings section with full customization
- System scrollbars (overlay during scroll, no space taken)

### 🐛 Code Quality
- All mutations properly persisted (matrix positions, sync IDs)
- Replaced print() with os.Logger
- Removed dead code (Quadrant.color/name)
- [weak self] in async closures
- Private saveLists(), public persist() API
- Empty catch blocks now log errors

---

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

[1.6.0]: https://github.com/santoru/docket/releases/tag/v1.6.0
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
