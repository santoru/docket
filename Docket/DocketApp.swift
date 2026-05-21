// DocketApp.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit
import Carbon.HIToolbox

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
    private var hotkeyRef: EventHotKeyRef?
    private var badgeTimer: Timer?
    private var lastHotkeyTime: Date = .distantPast

    var onQuickAdd: (() -> Void)?
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
        popover.behavior = .transient
        popover.delegate = self
        popover.setValue(true, forKeyPath: "shouldHideAnchor")
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let img = NSImage(contentsOfFile: Bundle.main.path(forResource: "menubar-icon", ofType: "png") ?? "")
            img?.isTemplate = true
            img?.size = NSSize(width: 18, height: 18)
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
        menu.addItem(NSMenuItem(title: "New Task", action: #selector(menuNewTask), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())

        let overdueCount = Store.shared.items.filter { !$0.isCompleted && $0.isOverdue }.count
        if overdueCount > 0 {
            menu.addItem(NSMenuItem(title: "⚠️ \(overdueCount) Overdue", action: nil, keyEquivalent: ""))
        }

        let todayCount = Store.shared.badgeCount
        menu.addItem(NSMenuItem(title: "\(todayCount) due today", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "GitHub", action: #selector(menuGitHub), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Docket", action: #selector(menuQuit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuNewTask() {
        if !popover.isShown { togglePopover() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.onQuickAdd?() }
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

            let x = button.bounds.width - width / 2 - 1
            let y = button.bounds.height - height + 2

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

        let keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        let code = keyCode > 0 ? keyCode : UInt32(kVK_ANSI_D)
        let mods = modifiers > 0 ? modifiers : UInt32(cmdKey | shiftKey)

        var hotKeyID = EventHotKeyID(signature: OSType(0x444B5420), id: 1) // var required by Carbon API
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(code, mods, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr { hotkeyRef = ref }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            AppDelegate.shared?.handleHotkey()
            return noErr
        }, 1, &eventType, nil, nil)
    }

    private func unregisterHotkey() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.onQuickAdd?() }
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
            self?.closePopover()
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
}
