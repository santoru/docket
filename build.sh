#!/bin/bash
# build.sh — Compile Docket into a macOS .app bundle
# Usage: ./build.sh
# Requires: Xcode Command Line Tools (swiftc)
set -e

APP_NAME="Docket"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SRC_DIR="$SCRIPT_DIR/Docket"

echo "🔨 Building $APP_NAME..."

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

# Compile all Swift source files
swiftc \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework UserNotifications \
    -framework ServiceManagement \
    -framework Carbon \
    -framework EventKit \
    -parse-as-library \
    -suppress-warnings \
    "$SRC_DIR/Models/ReminderOffset.swift" \
    "$SRC_DIR/Models/TodoItem.swift" \
    "$SRC_DIR/Models/TaskList.swift" \
    "$SRC_DIR/Models/TaskLabel.swift" \
    "$SRC_DIR/Models/Recurrence.swift" \
    "$SRC_DIR/Models/Quadrant.swift" \
    "$SRC_DIR/Models/AppTheme.swift" \
    "$SRC_DIR/Models/SortMode.swift" \
    "$SRC_DIR/Models/Strings.swift" \
    "$SRC_DIR/Services/NotificationManager.swift" \
    "$SRC_DIR/Services/Store.swift" \
    "$SRC_DIR/Services/DateParser.swift" \
    "$SRC_DIR/Services/DueDateFormatter.swift" \
    "$SRC_DIR/Services/RemindersSync.swift" \
    "$SRC_DIR/Views/TaskRowView.swift" \
    "$SRC_DIR/Views/SwipeableTaskRow.swift" \
    "$SRC_DIR/Views/CalendarPickerView.swift" \
    "$SRC_DIR/Views/TimePickerView.swift" \
    "$SRC_DIR/Views/ReminderPickerView.swift" \
    "$SRC_DIR/Views/RecurrencePickerView.swift" \
    "$SRC_DIR/Views/PriorityPickerView.swift" \
    "$SRC_DIR/Views/LabelPickerView.swift" \
    "$SRC_DIR/Views/QuadrantPickerView.swift" \
    "$SRC_DIR/Views/MatrixView.swift" \
    "$SRC_DIR/Views/ThemedToggle.swift" \
    "$SRC_DIR/Views/ConfettiView.swift" \
    "$SRC_DIR/Views/OnboardingView.swift" \
    "$SRC_DIR/Views/UndoToast.swift" \
    "$SRC_DIR/Views/VScroll.swift" \
    "$SRC_DIR/Views/TaskListView.swift" \
    "$SRC_DIR/Views/CreateTaskView.swift" \
    "$SRC_DIR/Views/TaskDetailView.swift" \
    "$SRC_DIR/Views/CompletedTasksView.swift" \
    "$SRC_DIR/Views/SettingsView.swift" \
    "$SRC_DIR/Views/ContentView.swift" \
    "$SRC_DIR/DocketApp.swift"

# Copy icons
cp "$SRC_DIR/icon.icns" "$APP_BUNDLE/Contents/Resources/"
cp "$SRC_DIR/menubar-icon.png" "$APP_BUNDLE/Contents/Resources/"
cp "$SRC_DIR/menubar-icon@2x.png" "$APP_BUNDLE/Contents/Resources/"

# Generate Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Docket</string>
    <key>CFBundleDisplayName</key>
    <string>Docket</string>
    <key>CFBundleIdentifier</key>
    <string>blog.insecurity.docket</string>
    <key>CFBundleVersion</key>
    <string>1.7.10</string>
    <key>CFBundleShortVersionString</key>
    <string>1.7.10</string>
    <key>CFBundleExecutable</key>
    <string>Docket</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSRemindersUsageDescription</key>
    <string>Docket syncs your tasks with Apple Reminders for iCloud, Siri, and Apple Watch access.</string>
</dict>
</plist>
PLIST

echo "✅ Built: $APP_BUNDLE"

# Sign the app so notifications and other system features work
codesign --force --sign - --identifier blog.insecurity.docket "$APP_BUNDLE"

echo ""
echo "To run:     open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
