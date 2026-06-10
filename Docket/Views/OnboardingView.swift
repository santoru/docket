// OnboardingView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// First-launch onboarding with staggered animations.
struct OnboardingView: View {
    @Binding var isPresented: Bool

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showTips = false
    @State private var showButton = false

    private let tips: [(icon: String, title: String, desc: String)] = [
        ("hand.draw", L10n.tipSwipe, L10n.tipSwipeDesc),
        ("arrow.up.arrow.down", L10n.tipReorder, L10n.tipReorderDesc),
        ("keyboard", L10n.tipShortcut, L10n.tipShortcutDesc),
        ("calendar", L10n.tipSmartDates, L10n.tipSmartDatesDesc),
        ("tag", L10n.tipLabels, L10n.tipLabelsDesc),
        ("list.bullet", L10n.tipLists, L10n.tipListsDesc),
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(accent)
                .scaleEffect(showIcon ? 1 : 0.5)
                .opacity(showIcon ? 1 : 0)
                .padding(.top, 24)

            // Title
            VStack(spacing: 4) {
                Text(L10n.welcome)
                    .font(.title3.bold())
                Text(L10n.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .offset(y: showTitle ? 0 : 10)
            .opacity(showTitle ? 1 : 0)

            // Tips
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.element.title) { index, tip in
                    HStack(spacing: 12) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tip.title).font(.subheadline.bold())
                            Text(tip.desc).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .offset(x: showTips ? 0 : -20)
                    .opacity(showTips ? 1 : 0)
                    .animation(.spring(duration: 0.4).delay(Double(index) * 0.08), value: showTips)
                }
            }
            .padding(.top, 8)

            Spacer()

            // Button
            Button {
                withAnimation(.spring(duration: 0.3)) { isPresented = false }
            } label: {
                Text(L10n.getStarted)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(accent.gradient))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(duration: 0.5)) { showIcon = true }
        withAnimation(.spring(duration: 0.4).delay(0.2)) { showTitle = true }
        withAnimation(.spring(duration: 0.4).delay(0.4)) { showTips = true }
        withAnimation(.spring(duration: 0.4).delay(0.8)) { showButton = true }
    }
}
