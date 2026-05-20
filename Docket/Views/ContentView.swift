// ContentView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Navigation destinations for the app's single NavigationStack.
enum NavDestination: Hashable {
    case create
    case detail(TodoItem)
    case completed
    case settings
}

/// Root view that applies the theme, handles onboarding, and routes navigation.
struct ContentView: View {
    @State private var path: [NavDestination] = []
    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("customSat") private var customSat: Double = 0.3
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("useGlass") private var useGlass = true

    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                TaskListView(path: $path)
                    .navigationDestination(for: NavDestination.self) { dest in
                        switch dest {
                        case .create:       CreateTaskView(path: $path)
                        case .detail(let t): TaskDetailView(item: t, path: $path)
                        case .completed:    CompletedTasksView(path: $path)
                        case .settings:     SettingsView(path: $path)
                        }
                    }
            }
            .opacity(showOnboarding ? 0 : 1)

            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
                    .transition(.opacity)
            }
        }
        .frame(width: 340, height: 480)
        .background(useGlass
            ? ThemeManager.resolvedBackground(themeRaw: themeRaw, customHue: customHue, customSat: customSat).opacity(ThemeManager.resolvedIsDark(themeRaw: themeRaw) ? 0.6 : 0.15)
            : ThemeManager.resolvedBackground(themeRaw: themeRaw, customHue: customHue, customSat: customSat)
        )
        .environment(\.colorScheme, ThemeManager.resolvedIsDark(themeRaw: themeRaw) ? .dark : .light)
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
                hasSeenOnboarding = true
            }
            // Register quick-add callback
            AppDelegate.shared?.onQuickAdd = {
                if path.last != .create {
                    path = [.create]
                }
            }
            // Register popover close callback — reset UI except task edit/create
            AppDelegate.shared?.onPopoverClose = {
                if let last = path.last {
                    switch last {
                    case .create, .detail: break // keep these open
                    default: path = []
                    }
                }
            }
            // Local keyboard monitor for navigation
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "n" {
                    if path.last != .create { path.append(.create) }
                    return nil
                }
                if event.keyCode == 53 { // Escape
                    if !path.isEmpty { path.removeLast() }
                    return nil
                }
                return event
            }
        }
    }
}
