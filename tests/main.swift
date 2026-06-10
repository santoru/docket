// main.swift — Docket logic test runner
// A dependency-free (no XCTest) harness for the app's pure logic.
// Built and run via ../run-tests.sh.

import Foundation
import AppKit
import SwiftUI

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

// MARK: - Run

testDateParser()
testRecurrence()
testDueDateFormatter()
testColorHex()
testMatrixLayout()
testTodoItemCodable()
testDocketExport()

print("\n\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
