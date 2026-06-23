// HotkeyMapping.swift
// Docket — pure helpers for the global hotkey.

import AppKit
import Carbon.HIToolbox

/// Pure conversions between Carbon modifier masks (the legacy representation the
/// app persists in `UserDefaults`) and Cocoa `NSEvent.ModifierFlags` (what the
/// runtime event monitors compare against). Kept free of any app state so it can
/// be unit-tested in isolation.
enum HotkeyMapping {
    /// Convert a Carbon modifier mask (`cmdKey`, `shiftKey`, `optionKey`,
    /// `controlKey`, OR-combined) into `NSEvent.ModifierFlags`.
    static func cocoaModifiers(fromCarbon carbonMods: UInt32) -> NSEvent.ModifierFlags {
        var mods: NSEvent.ModifierFlags = []
        if carbonMods & UInt32(cmdKey) != 0 { mods.insert(.command) }
        if carbonMods & UInt32(shiftKey) != 0 { mods.insert(.shift) }
        if carbonMods & UInt32(optionKey) != 0 { mods.insert(.option) }
        if carbonMods & UInt32(controlKey) != 0 { mods.insert(.control) }
        return mods
    }
}
