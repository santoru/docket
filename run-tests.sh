#!/bin/bash
# run-tests.sh — Compile and run Docket's pure-logic test suite.
# Usage: ./run-tests.sh
# Requires: Xcode Command Line Tools (swiftc)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/Docket"
BUILD_DIR="$SCRIPT_DIR/build"
BIN="$BUILD_DIR/DocketTests"

mkdir -p "$BUILD_DIR"

echo "🧪 Compiling tests..."
swiftc \
    -o "$BIN" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -suppress-warnings \
    "$SRC/Models/ReminderOffset.swift" \
    "$SRC/Models/Recurrence.swift" \
    "$SRC/Models/Quadrant.swift" \
    "$SRC/Models/SortMode.swift" \
    "$SRC/Models/AppTheme.swift" \
    "$SRC/Models/HotkeyMapping.swift" \
    "$SRC/Models/ColorPalette.swift" \
    "$SRC/Models/IconPalette.swift" \
    "$SRC/Models/TaskLabel.swift" \
    "$SRC/Models/TaskList.swift" \
    "$SRC/Models/TodoItem.swift" \
    "$SRC/Models/MatrixLayout.swift" \
    "$SRC/Models/Strings.swift" \
    "$SRC/Services/DateParser.swift" \
    "$SRC/Services/DueDateFormatter.swift" \
    "$SCRIPT_DIR/tests/main.swift"

echo "🏃 Running tests..."
echo ""
"$BIN"
