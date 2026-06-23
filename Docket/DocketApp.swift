// DocketApp.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit
import Carbon.HIToolbox // For kVK_* virtual key codes only

@main
struct DocketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var hotkeyGlobalMonitor: Any?
    private var hotkeyLocalMonitor: Any?
    private var badgeTimer: Timer?
    private var lastHotkeyTime: Date = .distantPast

    var onQuickAdd: (() -> Void)?
    var onTipJar: (() -> Void)?
    var onPopoverClose: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)
        NotificationManager.shared.requestPermission()

        setupPopover()
        setupStatusItem()
        setupBadgeTimer()
        registerHotkey()
    }

    // MARK: - Setup

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .applicationDefined
        popover.delegate = self
        popover.setValue(true, forKeyPath: "shouldHideAnchor")
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let img = NSImage(contentsOfFile: Bundle.main.path(forResource: "menubar-icon@2x", ofType: "png") ?? "")
                ?? NSImage(contentsOfFile: Bundle.main.path(forResource: "menubar-icon", ofType: "png") ?? "")
            img?.size = NSSize(width: 18, height: 18)
            img?.isTemplate = true
            button.image = img ?? NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Docket")
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateBadge()
    }

    private func setupBadgeTimer() {
        badgeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBadge()
        }
    }

    // MARK: - Click Handling

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.newTask, action: #selector(menuNewTask), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())

        let overdueCount = Store.shared.items.filter { !$0.isCompleted && $0.isOverdue }.count
        if overdueCount > 0 {
            menu.addItem(NSMenuItem(title: L10n.menuOverdue(overdueCount), action: nil, keyEquivalent: ""))
        }

        let todayCount = Store.shared.badgeCount
        menu.addItem(NSMenuItem(title: L10n.menuDueToday(todayCount), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "☕ \(L10n.tipJar)", action: #selector(menuTipJar), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "GitHub", action: #selector(menuGitHub), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L10n.menuQuit, action: #selector(menuQuit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuNewTask() {
        if !popover.isShown { togglePopover() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.onQuickAdd?() }
    }

    @objc private func menuTipJar() {
        if !popover.isShown { togglePopover() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.onTipJar?() }
    }

    @objc private func menuGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/santoru/docket")!)
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - Badge

    func updateBadge() {
        let count = Store.shared.badgeCount
        guard let button = statusItem.button else { return }

        button.subviews.forEach { $0.removeFromSuperview() }
        button.title = ""

        if count > 0 {
            let height: CGFloat = 14
            let text = "\(count)"
            let width: CGFloat = text.count > 1 ? height + 4 : height // pill for 2+ digits, circle for 1

            let x = button.bounds.width - width - 1
            let y = button.bounds.height - height + 1

            let bg = NSView(frame: NSRect(x: x, y: y, width: width, height: height))
            bg.wantsLayer = true
            bg.layer?.backgroundColor = NSColor.systemRed.cgColor
            bg.layer?.cornerRadius = height / 2

            let label = NSTextField(labelWithString: text)
            label.font = NSFont.systemFont(ofSize: 9, weight: .bold)
            label.textColor = .white
            label.alignment = .center
            label.isBezeled = false
            label.drawsBackground = false
            label.frame = NSRect(x: x, y: y, width: width, height: height)

            button.addSubview(bg)
            button.addSubview(label)
        }
    }

    // MARK: - Global Hotkey

    func registerHotkey() {
        unregisterHotkey()

        let enabled = UserDefaults.standard.object(forKey: "hotkeyEnabled") as? Bool ?? true
        guard enabled else { return }

        let keyCode = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
        let code = keyCode > 0 ? UInt16(keyCode) : UInt16(kVK_ANSI_D)
        let targetMods = HotkeyMapping.cocoaModifiers(fromCarbon: UInt32(modifiers > 0 ? modifiers : Int(cmdKey | shiftKey)))

        func matches(_ event: NSEvent) -> Bool {
            event.keyCode == code &&
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == targetMods
        }

        // Global monitor: fires only when another app is frontmost (Docket
        // inactive) — this is the common "summon Docket" path.
        hotkeyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard matches(event) else { return }
            DispatchQueue.main.async { self?.handleHotkey() }
        }

        // Local monitor: fires only when Docket itself is frontmost (e.g. the
        // popover is open). Without this, the documented double-press quick-add
        // would never trigger, because the global monitor is silent while the
        // app is active. Returning nil consumes the event so it doesn't also
        // reach a focused text field.
        hotkeyLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard matches(event) else { return event }
            self?.handleHotkey()
            return nil
        }
    }

    private func unregisterHotkey() {
        if let monitor = hotkeyGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyGlobalMonitor = nil
        }
        if let monitor = hotkeyLocalMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyLocalMonitor = nil
        }
    }

    private func handleHotkey() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastHotkeyTime)
        lastHotkeyTime = now

        if popover.isShown && elapsed < 0.8 {
            onQuickAdd?()
        } else {
            togglePopover()
            if elapsed < 0.8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.onQuickAdd?() }
            }
        }
    }

    // MARK: - Popover

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            // Only close if our app lost focus (click went to another app, not a system panel like emoji picker)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if !NSApp.isActive {
                    self?.closePopover()
                }
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
        updateBadge()
        onPopoverClose?()
        NotificationCenter.default.post(name: .popoverDidClose, object: nil)
    }
}

extension Notification.Name {
    static let popoverDidClose = Notification.Name("DocketPopoverDidClose")
    static let scrollToTipJar = Notification.Name("DocketScrollToTipJar")
}
