// main.swift — Docket logic test runner
// A dependency-free (no XCTest) harness for the app's pure logic.
// Built and run via ../run-tests.sh.

import Foundation
import AppKit
import SwiftUI
import Carbon.HIToolbox

// MARK: - Tiny harness

var passed = 0
var failed = 0

func expect(_ condition: Bool, _ message: String, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        FileHandle.standardError.write("❌ [line \(line)] \(message)\n".data(using: .utf8)!)
    }
}

func expectEqual<T: Equatable>(_ a: T, _ b: T, _ message: String, line: Int = #line) {
    expect(a == b, "\(message) — expected \(b), got \(a)", line: line)
}

let cal = Calendar.current

// MARK: - DateParser

func testDateParser() {
    expect(DateParser.parse("") == nil, "empty string parses to nil")
    expect(DateParser.parse("   ") == nil, "whitespace parses to nil")

    if let noon = DateParser.parse("noon") {
        expectEqual(cal.component(.hour, from: noon), 12, "noon hour is 12")
        expect(cal.isDateInToday(noon), "noon is today")
    } else { expect(false, "noon should parse") }

    if let t = DateParser.parse("tomorrow 3pm") {
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        expect(cal.isDate(t, inSameDayAs: tomorrow), "tomorrow 3pm is tomorrow")
        expectEqual(cal.component(.hour, from: t), 15, "3pm is hour 15")
    } else { expect(false, "tomorrow 3pm should parse") }

    let before = Date()
    if let t = DateParser.parse("in 2 hours") {
        let diff = t.timeIntervalSince(before)
        expect(abs(diff - 7200) < 120, "in 2 hours ≈ +7200s (got \(diff))")
    } else { expect(false, "in 2 hours should parse") }

    if let t = DateParser.parse("in 3 days") {
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: t)).day
        expectEqual(days, 3, "in 3 days is +3 days")
    } else { expect(false, "in 3 days should parse") }

    if let fri = DateParser.parse("friday") {
        expectEqual(cal.component(.weekday, from: fri), 6, "friday is weekday 6")
        expect(fri > Date(), "bare weekday is in the future")
    } else { expect(false, "friday should parse") }

    if let mon = DateParser.parse("next monday") {
        expectEqual(cal.component(.weekday, from: mon), 2, "next monday is weekday 2")
    } else { expect(false, "next monday should parse") }
}

// MARK: - Recurrence

func testRecurrence() {
    var comps = DateComponents()
    comps.year = 2026; comps.month = 1; comps.day = 15; comps.hour = 10
    let base = cal.date(from: comps)!

    let daily = Recurrence(frequency: .daily, interval: 2, endDate: nil)
    expectEqual(daily.nextDueDate(from: base), cal.date(byAdding: .day, value: 2, to: base), "daily/2 → +2 days")

    let weekly = Recurrence(frequency: .weekly, interval: 1, endDate: nil)
    expectEqual(weekly.nextDueDate(from: base), cal.date(byAdding: .day, value: 7, to: base), "weekly/1 → +7 days")

    let monthly = Recurrence(frequency: .monthly, interval: 1, endDate: nil)
    if let next = monthly.nextDueDate(from: base) {
        expectEqual(cal.component(.month, from: next), 2, "monthly/1 → February")
    } else { expect(false, "monthly should produce a date") }

    // endDate cutoff: next occurrence is beyond the end date → nil
    let capped = Recurrence(frequency: .weekly, interval: 1, endDate: cal.date(byAdding: .day, value: 3, to: base))
    expect(capped.nextDueDate(from: base) == nil, "recurrence past endDate → nil")
}

// MARK: - DueDateFormatter

func testDueDateFormatter() {
    let today = cal.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
    expect(DueDateFormatter.format(today).contains("Today"), "today is labeled Today")

    let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
    expect(DueDateFormatter.format(tomorrow).contains("Tomorrow"), "tomorrow is labeled Tomorrow")
}

// MARK: - Color(hex:)

func rgba(_ c: Color) -> (r: Double, g: Double, b: Double, a: Double) {
    let ns = NSColor(c).usingColorSpace(.sRGB) ?? NSColor(c)
    return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent), Double(ns.alphaComponent))
}

func testColorHex() {
    let red = rgba(Color(hex: "#FF0000"))
    expect(abs(red.r - 1) < 0.02 && red.g < 0.02 && red.b < 0.02, "#FF0000 is red")

    let short = rgba(Color(hex: "0F0"))
    expect(short.g > 0.95 && short.r < 0.05, "#0F0 shorthand expands to green")

    let alpha = rgba(Color(hex: "#00FF0080"))
    expect(abs(alpha.a - 0.5) < 0.02, "#RRGGBBAA alpha ≈ 0.5 (got \(alpha.a))")

    let invalid = rgba(Color(hex: "nothex"))
    expect(abs(invalid.r - 0.6) < 0.02 && abs(invalid.g - 0.6) < 0.02, "invalid hex falls back to gray")
}

// MARK: - Hotkey modifier mapping

func testHotkeyMapping() {
    // ⌘⇧ → command + shift
    let cmdShift = HotkeyMapping.cocoaModifiers(fromCarbon: UInt32(cmdKey | shiftKey))
    expect(cmdShift.contains(.command), "cmdKey maps to .command")
    expect(cmdShift.contains(.shift), "shiftKey maps to .shift")
    expect(!cmdShift.contains(.option), "option absent when not set")
    expect(!cmdShift.contains(.control), "control absent when not set")

    // ⌃⌥ → control + option
    let ctrlOpt = HotkeyMapping.cocoaModifiers(fromCarbon: UInt32(controlKey | optionKey))
    expect(ctrlOpt.contains(.control), "controlKey maps to .control")
    expect(ctrlOpt.contains(.option), "optionKey maps to .option")
    expect(!ctrlOpt.contains(.command), "command absent when not set")

    // empty mask → no flags
    expect(HotkeyMapping.cocoaModifiers(fromCarbon: 0).isEmpty, "zero mask maps to empty flags")

    // all four set
    let all = HotkeyMapping.cocoaModifiers(fromCarbon: UInt32(cmdKey | shiftKey | optionKey | controlKey))
    expect(all.contains(.command) && all.contains(.shift) && all.contains(.option) && all.contains(.control),
           "all four Carbon modifiers map to all four Cocoa flags")
}

// MARK: - Dark-mode label color adaptation

func testColorAdaptation() {
    // The Midnight theme is always dark regardless of system appearance, so we
    // can exercise the dark-mode branch deterministically (no NSApp dependency).
    let midnight = AppTheme.midnight.rawValue

    func luminance(_ t: (r: Double, g: Double, b: Double, a: Double)) -> Double {
        0.299 * t.r + 0.587 * t.g + 0.114 * t.b
    }

    // A dark label (Graphite) must be lightened so it stays legible on a dark surface.
    let graphite = Color(hex: "#374151")
    let lifted = graphite.adaptedForCurrentScheme(themeRaw: midnight)
    expect(luminance(rgba(lifted)) > luminance(rgba(graphite)) + 0.05,
           "dark label is lightened in dark mode")

    // A bright label (Yellow) is already legible and must be returned unchanged.
    let yellow = Color(hex: "#EAB308")
    let y0 = rgba(yellow)
    let y1 = rgba(yellow.adaptedForCurrentScheme(themeRaw: midnight))
    expect(abs(y1.r - y0.r) < 0.01 && abs(y1.g - y0.g) < 0.01 && abs(y1.b - y0.b) < 0.01,
           "bright label is unchanged in dark mode")
}

// MARK: - MatrixLayout

func testMatrixLayout() {
    let size = CGSize(width: 200, height: 200)
    let seeds = Array(repeating: CGPoint(x: 0.5, y: 0.5), count: 5)
    let positions = MatrixLayout.resolvePositions(seeds: seeds, in: size, maxChars: 6, lineCount: 1)

    expectEqual(positions.count, 5, "resolver returns one position per seed")

    let pill = MatrixLayout.pillSize(maxChars: 6, lineCount: 1, in: size.width)
    expect(pill.width > 0 && pill.height > 0, "pillSize is positive")

    // All centers within bounds.
    for p in positions {
        expect(p.x >= pill.width / 2 - 0.001 && p.x <= size.width - pill.width / 2 + 0.001
               && p.y >= pill.height / 2 - 0.001 && p.y <= size.height - pill.height / 2 + 0.001,
               "pill center stays inside the box")
    }

    // No two inflated rects intersect (the whole point of the resolver).
    func rect(_ p: CGPoint) -> CGRect {
        CGRect(x: p.x - pill.width / 2 - 2, y: p.y - pill.height / 2 - 2,
               width: pill.width + 4, height: pill.height + 4)
    }
    for i in 0..<positions.count {
        for j in (i + 1)..<positions.count {
            expect(!rect(positions[i]).intersects(rect(positions[j])), "pills \(i) and \(j) do not overlap")
        }
    }

    expect(MatrixLayout.resolvePositions(seeds: [], in: size, maxChars: 6, lineCount: 1).isEmpty,
           "empty seeds → empty result")
    expect(MatrixLayout.resolvePositions(seeds: seeds, in: .zero, maxChars: 6, lineCount: 1).allSatisfy { $0 == .zero },
           "zero size → all .zero")
}

// MARK: - TodoItem Codable

func testTodoItemCodable() {
    var item = TodoItem(title: "Round trip", notes: "n", priority: .high)
    item.sortOrder = 7
    item.labelIds = [UUID()]
    let data = try! JSONEncoder().encode(item)
    let decoded = try! JSONDecoder().decode(TodoItem.self, from: data)
    expectEqual(decoded, item, "TodoItem survives an encode/decode round trip")

    // Backward compatibility: a minimal payload missing optional fields.
    let minimal = """
    {"id":"\(UUID().uuidString)","title":"Old","notes":"","createdAt":0,"priorityRaw":1,"reminderOffsetRaw":3}
    """.data(using: .utf8)!
    do {
        let old = try JSONDecoder().decode(TodoItem.self, from: minimal)
        expectEqual(old.sortOrder, 0, "missing sortOrder defaults to 0")
        expect(old.labelIds.isEmpty, "missing labelIds defaults to []")
        expect(old.dueDate == nil, "missing dueDate decodes as nil")
    } catch {
        expect(false, "minimal legacy payload should decode: \(error)")
    }
}

// MARK: - DocketExport schema version

func testDocketExport() {
    let withVersion = """
    {"schemaVersion":1,"lists":[],"labels":[],"tasks":[]}
    """.data(using: .utf8)!
    let a = try! JSONDecoder().decode(DocketExport.self, from: withVersion)
    expectEqual(a.schemaVersion, 1, "schemaVersion decodes when present")

    let withoutVersion = """
    {"lists":[],"labels":[],"tasks":[]}
    """.data(using: .utf8)!
    let b = try! JSONDecoder().decode(DocketExport.self, from: withoutVersion)
    expect(b.schemaVersion == nil, "schemaVersion absent → nil (backward compatible)")
}

// MARK: - ColorPalette + Color.toHex round-trip

func testColorPalette() {
    // Every preset is a valid hex string and round-trips through Color(hex:) → toHex().
    for preset in ColorPalette.presets {
        let c = Color(hex: preset.hex)
        if let back = c.toHex() {
            expectEqual(back.uppercased(), preset.hex.uppercased(),
                        "palette '\(preset.name)' (\(preset.hex)) round-trips through Color↔hex")
        } else {
            expect(false, "palette '\(preset.name)' (\(preset.hex)) failed toHex()")
        }
    }

    expectEqual(ColorPalette.presets.count, 20, "palette has exactly 20 colors")

    // Deterministic fallback is stable across calls and stays inside the palette.
    let key = UUID().uuidString
    let a = ColorPalette.deterministic(for: key)
    let b = ColorPalette.deterministic(for: key)
    expectEqual(a, b, "deterministic() is stable for the same key")
    expect(ColorPalette.presets.contains(where: { $0.hex == a }),
           "deterministic() returns a palette member")

    // Different keys mostly map to different colors (sanity — not a strict guarantee).
    let distinct = Set((0..<50).map { ColorPalette.deterministic(for: "key-\($0)") })
    expect(distinct.count >= 10, "deterministic() spreads across the palette (got \(distinct.count) distinct)")
}

// MARK: - TaskList color resolution + Codable backwards compatibility

func testTaskListColor() {
    // 1. A list without a stored colorHex still has a (deterministic) color.
    let listA = TaskList(name: "Inbox")
    let resolvedA = listA.resolvedHex
    expect(ColorPalette.presets.contains(where: { $0.hex == resolvedA }),
           "list without colorHex resolves to a palette color")
    expectEqual(listA.resolvedHex, resolvedA, "resolvedHex is stable for the same list instance")

    // 2. A list with a stored colorHex returns it verbatim.
    var listB = TaskList(name: "Work", colorHex: "#FF00AA")
    expectEqual(listB.resolvedHex, "#FF00AA", "stored colorHex wins over fallback")
    listB.colorHex = nil
    expect(ColorPalette.presets.contains(where: { $0.hex == listB.resolvedHex }),
           "clearing colorHex falls back to a palette color")

    // 3. Legacy lists.json (without the colorHex field) decodes cleanly.
    let id = UUID().uuidString
    let createdAt = Date().timeIntervalSinceReferenceDate
    let legacyJSON = """
    {"id":"\(id)","name":"Legacy","createdAt":\(createdAt),"isDefault":false}
    """.data(using: .utf8)!
    do {
        let decoded = try JSONDecoder().decode(TaskList.self, from: legacyJSON)
        expect(decoded.colorHex == nil, "legacy lists.json decodes with nil colorHex")
        expect(ColorPalette.presets.contains(where: { $0.hex == decoded.resolvedHex }),
               "legacy list still resolves to a palette color")
    } catch {
        expect(false, "legacy lists.json should decode: \(error)")
    }

    // 4. Codable round-trip preserves a stored colorHex.
    let original = TaskList(name: "Travel", colorHex: "#0EA5E9")
    let data = try! JSONEncoder().encode(original)
    let round = try! JSONDecoder().decode(TaskList.self, from: data)
    expectEqual(round.colorHex, "#0EA5E9", "TaskList.colorHex survives encode/decode")
    expectEqual(round.name, "Travel", "TaskList.name survives encode/decode")
}

// MARK: - IconPalette

func testIconPalette() {
    expectEqual(IconPalette.presets.count, 15, "icon palette has exactly 15 icons")
    let unique = Set(IconPalette.presets)
    expectEqual(unique.count, IconPalette.presets.count, "all icons are distinct")
    expect(IconPalette.presets.contains(IconPalette.defaultIcon),
           "defaultIcon is in the preset list")

    // Every preset has a non-empty localized display name.
    for icon in IconPalette.presets {
        let name = IconPalette.displayName(icon)
        expect(!name.isEmpty, "displayName for '\(icon)' is non-empty")
    }

    // Unknown icon falls back to its raw symbol name.
    let unknown = "this.is.not.a.preset"
    expectEqual(IconPalette.displayName(unknown), unknown,
                "displayName falls back to the raw symbol for unknown icons")
}

// MARK: - Run

testDateParser()
testRecurrence()
testDueDateFormatter()
testColorHex()
testHotkeyMapping()
testColorAdaptation()
testColorPalette()
testTaskListColor()
testIconPalette()
testMatrixLayout()
testTodoItemCodable()
testDocketExport()

print("\n\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
