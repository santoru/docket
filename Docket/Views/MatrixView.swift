// MatrixView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Eisenhower Matrix view with free-positioned, draggable task pills.
///
/// Design notes:
///  • Quadrants use ultra-subtle tinted fills + hairline borders for a quiet,
///    professional feel — the colour is for *identity*, not for grabbing attention.
///  • Pills truncate text natively via SwiftUI (`lineLimit` + `truncationMode`),
///    so long titles get a real ellipsis instead of a hard `String.prefix` cut.
///  • An anti-collision pass at the quadrant level offsets pills that would
///    otherwise sit on top of each other, so dots can never fully overlap.
struct MatrixView: View {
    @Binding var path: [NavDestination]
    var store = Store.shared

    @AppStorage("appTheme") private var themeRaw: Int = AppTheme.white.rawValue
    @AppStorage("customHue") private var customHue: Double = 0.55
    @AppStorage("matrixDoFirstColor") private var doFirstColor = "#EF4444"
    @AppStorage("matrixScheduleColor") private var scheduleColor = "#3B82F6"
    @AppStorage("matrixDelegateColor") private var delegateColor = "#F59E0B"
    @AppStorage("matrixEliminateColor") private var eliminateColor = "#9CA3AF"
    @AppStorage("matrixDoFirstLabel") private var doFirstLabel = "Do First"
    @AppStorage("matrixScheduleLabel") private var scheduleLabel = "Schedule"
    @AppStorage("matrixDelegateLabel") private var delegateLabel = "Delegate"
    @AppStorage("matrixEliminateLabel") private var eliminateLabel = "Eliminate"
    @AppStorage("matrixLabelLength") private var matrixLabelLength = 14
    @AppStorage("matrixLineCount") private var matrixLineCount = 1
    @AppStorage("matrixShowAxes") private var matrixShowAxes = true
    @AppStorage("matrixShowBadges") private var matrixShowBadges = true

    private var accent: Color { ThemeManager.resolvedAccent(themeRaw: themeRaw, customHue: customHue) }

    private func quadrantColor(_ q: Quadrant) -> Color {
        switch q {
        case .doFirst: Color(hex: doFirstColor)
        case .schedule: Color(hex: scheduleColor)
        case .delegate: Color(hex: delegateColor)
        case .eliminate: Color(hex: eliminateColor)
        }
    }

    private func quadrantLabel(_ q: Quadrant) -> String {
        switch q {
        case .doFirst: doFirstLabel
        case .schedule: scheduleLabel
        case .delegate: delegateLabel
        case .eliminate: eliminateLabel
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (fixed)
            HStack {
                Button { path.removeLast() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(.quaternary.opacity(0.5)))
                }.buttonStyle(.plain)
                Spacer()
                Text("Eisenhower Matrix").font(.headline)
                Spacer()
                Color.clear.frame(width: 28, height: 28)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            VScroll {
                VStack(spacing: 0) {
                    Spacer().frame(height: 14)

                    if matrixShowAxes { axisHeader }

                    HStack(spacing: 0) {
                        if matrixShowAxes { yAxisLabels }

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                quadrantBox(.doFirst)
                                quadrantBox(.schedule)
                            }
                            HStack(spacing: 4) {
                                quadrantBox(.delegate)
                                quadrantBox(.eliminate)
                            }
                        }
                    }
                    .padding(.horizontal, 10)

                    unassignedSection
                }
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Axis Labels

    private var axisHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 16)
            HStack(spacing: 4) {
                axisLabel("URGENT")
                axisLabel("NOT URGENT")
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var yAxisLabels: some View {
        VStack(spacing: 4) {
            verticalAxisLabel("IMPORTANT").frame(height: 140)
            verticalAxisLabel("NOT").frame(height: 140)
        }
        .frame(width: 16)
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8.5, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
    }

    private func verticalAxisLabel(_ text: String) -> some View {
        VStack(spacing: 1) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, c in
                Text(String(c))
                    .font(.system(size: 7.5, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Quadrant Box

    private func quadrantBox(_ quadrant: Quadrant) -> some View {
        let tasks = store.activeTasks.filter { $0.quadrant == quadrant }
        let color = quadrantColor(quadrant)
        let label = quadrantLabel(quadrant)

        return GeometryReader { geo in
            let resolved = resolvePositions(for: tasks, in: geo.size)

            ZStack(alignment: .topLeading) {
                // Background — quiet tinted fill + hairline border.
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(color.opacity(0.18), lineWidth: 0.75)
                    )

                // Header (icon + small-caps label)
                HStack(spacing: 5) {
                    Image(systemName: quadrant.icon)
                        .font(.system(size: 8.5, weight: .semibold))
                    Text(label.uppercased())
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(0.9)
                }
                .foregroundStyle(color)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)

                // Count badge — minimal pill, top-right.
                if matrixShowBadges && !tasks.isEmpty {
                    Text("\(tasks.count)")
                        .font(.system(size: 9, weight: .semibold).monospacedDigit())
                        .foregroundStyle(color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule().fill(color.opacity(0.14))
                        )
                        .position(x: geo.size.width - 16, y: 13)
                }

                // Tasks — positions are resolved by the parent so they never fully overlap.
                ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, item in
                    TaskDot(
                        item: item,
                        quadrant: quadrant,
                        color: color,
                        maxChars: matrixLabelLength,
                        bounds: geo.size,
                        initialPosition: resolved[idx],
                        onTap: { path.append(.detail(item)) }
                    )
                }
            }
            .dropDestination(for: String.self) { items, _ in
                for idString in items {
                    if let uuid = UUID(uuidString: idString),
                       let i = store.items.firstIndex(where: { $0.id == uuid }) {
                        store.items[i].quadrant = quadrant
                        store.items[i].matrixX = 0.5
                        store.items[i].matrixY = 0.5
                        store.persist()
                    }
                }
                return true
            }
        }
        .frame(height: 140)
    }

    // MARK: - Anti-Collision

    /// The expected on-screen size of a task pill, given the current settings
    /// and the available quadrant width. Both `TaskDot` and the resolver use
    /// these dimensions so positioning math stays in sync with what's drawn.
    static func pillSize(maxChars: Int, lineCount: Int, in containerWidth: CGFloat) -> CGSize {
        // Match the magic numbers used by `TaskDot`'s layout below.
        let rawTextWidth = max(36, CGFloat(maxChars) * 5.6)
        let textCap = max(20, containerWidth - 26 - 8)   // dot+spacing+padding+small margin
        let textWidth = min(rawTextWidth, textCap)
        let lineHeight: CGFloat = 13
        return CGSize(
            width: textWidth + 26,                       // text + dot(5) + spacing(5) + 2*hPad(8)
            height: CGFloat(lineCount) * lineHeight + 9  // text height + 2*vPad(4.5)
        )
    }

    /// Compute on-screen positions for the given tasks. If a task's stored
    /// position would land on top of an already-placed one, spiral outward by
    /// small increments until it's clear of every previously placed pill.
    /// Bounds are derived from the actual pill size so no pill overflows the
    /// quadrant border.
    private func resolvePositions(for tasks: [TodoItem], in size: CGSize) -> [CGPoint] {
        guard size.width > 0, size.height > 0 else {
            return Array(repeating: .zero, count: tasks.count)
        }

        let pill = Self.pillSize(maxChars: matrixLabelLength, lineCount: matrixLineCount, in: size.width)
        let pad: CGFloat = 4

        // Inset bounds: pill *centre* must stay at least half a pill + pad
        // away from each edge so the whole pill sits inside the box.
        let xMin = pill.width / 2 + pad
        let xMax = max(xMin + 1, size.width - pill.width / 2 - pad)
        let yMin = pill.height / 2 + pad
        let yMax = max(yMin + 1, size.height - pill.height / 2 - pad)

        // Minimum centre-to-centre distance between any two pills.
        let minDist: CGFloat = 38

        var placed: [CGPoint] = []
        placed.reserveCapacity(tasks.count)

        for item in tasks {
            let baseX = (item.matrixX ?? 0.5) * size.width
            let baseY = (item.matrixY ?? 0.5) * size.height
            var p = clampPoint(CGPoint(x: baseX, y: baseY),
                               xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)

            var attempt = 0
            while attempt < 28 && placed.contains(where: { hypot(p.x - $0.x, p.y - $0.y) < minDist }) {
                attempt += 1
                // Stable spiral: each subsequent attempt rotates ~110° and grows the radius.
                let angle = Double(attempt) * 1.92
                let radius = 14.0 + Double(attempt) * 5.0
                p = clampPoint(
                    CGPoint(x: baseX + CGFloat(cos(angle) * radius),
                            y: baseY + CGFloat(sin(angle) * radius)),
                    xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax
                )
            }
            placed.append(p)
        }
        return placed
    }

    private func clampPoint(_ p: CGPoint, xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) -> CGPoint {
        CGPoint(
            x: min(max(p.x, xMin), xMax),
            y: min(max(p.y, yMin), yMax)
        )
    }

    // MARK: - Unassigned

    private var unassignedSection: some View {
        let unassigned = store.activeTasks.filter { $0.quadrant == nil }
        return Group {
            if !unassigned.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("UNASSIGNED")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("\(unassigned.count)")
                            .font(.system(size: 9, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(unassigned) { item in
                                Button { path.append(.detail(item)) } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(priorityColor(item.priority))
                                            .frame(width: 5, height: 5)
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(.regularMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(.quaternary, lineWidth: 0.5)
                                    )
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: 140)
                                }
                                .buttonStyle(.plain)
                                .draggable(item.id.uuidString)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high: Color(red: 0.95, green: 0.50, blue: 0.55)
        case .medium: Color(red: 0.95, green: 0.75, blue: 0.40)
        case .low: Color(red: 0.45, green: 0.72, blue: 0.95)
        }
    }
}

// MARK: - Task Dot

/// A draggable task pill rendered inside a quadrant. The pill seeds its
/// position from the parent (which has already run the anti-collision pass),
/// so two pills with identical stored coordinates will never sit exactly on
/// top of each other.
struct TaskDot: View {
    let item: TodoItem
    let quadrant: Quadrant
    let color: Color
    let maxChars: Int
    let bounds: CGSize
    let initialPosition: CGPoint
    let onTap: () -> Void

    @AppStorage("matrixLineCount") private var matrixLineCount = 1
    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isHovering = false

    /// Width budget for the title text. Capped to the available container so
    /// the pill itself never exceeds the quadrant box.
    private var textMaxWidth: CGFloat {
        let raw = max(36, CGFloat(maxChars) * 5.6)
        let cap = max(20, bounds.width - 26 - 8)
        return min(raw, cap)
    }

    /// Real on-screen size of this pill — used to clamp positions so the pill
    /// stays fully inside the quadrant border.
    private var pillSize: CGSize {
        MatrixView.pillSize(maxChars: maxChars, lineCount: matrixLineCount, in: bounds.width)
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Group {
                if matrixLineCount == 1 {
                    // Single-line: use marquee that scrolls on hover when truncated.
                    MarqueeText(
                        text: item.title,
                        font: .system(size: 10, weight: .medium),
                        maxWidth: textMaxWidth,
                        isHovering: isHovering
                    )
                } else {
                    // Multi-line: native ellipsis truncation, no marquee.
                    Text(item.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(matrixLineCount)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: textMaxWidth, alignment: .leading)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(color.opacity(isDragging ? 0.45 : 0.18), lineWidth: 0.6)
        )
        .shadow(
            color: .black.opacity(isDragging ? 0.18 : 0.06),
            radius: isDragging ? 6 : 1.5,
            x: 0,
            y: isDragging ? 3 : 0.5
        )
        .scaleEffect(isDragging ? 1.06 : (isHovering ? 1.02 : 1.0))
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .zIndex(isDragging ? 10 : (isHovering ? 5 : 0))
        .onHover { isHovering = $0 }
        .gesture(
            DragGesture(coordinateSpace: .named("matrix"))
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    dragOffset = .zero

                    let store = Store.shared
                    guard let i = store.items.firstIndex(where: { $0.id == item.id }) else { return }

                    let finalX = position.x + value.translation.width
                    let finalY = position.y + value.translation.height

                    if finalX < 0 || finalX > bounds.width || finalY < 0 || finalY > bounds.height {
                        // Crossed boundary — determine target quadrant.
                        let wentLeft = finalX < 0
                        let wentRight = finalX > bounds.width
                        let wentUp = finalY < 0
                        let wentDown = finalY > bounds.height

                        let newQuadrant: Quadrant? = switch quadrant {
                        case .doFirst:   wentRight ? .schedule  : wentDown ? .delegate  : nil
                        case .schedule:  wentLeft  ? .doFirst   : wentDown ? .eliminate : nil
                        case .delegate:  wentRight ? .eliminate : wentUp   ? .doFirst   : nil
                        case .eliminate: wentLeft  ? .delegate  : wentUp   ? .schedule  : nil
                        }

                        if let target = newQuadrant {
                            store.items[i].quadrant = target
                            store.items[i].matrixX = 0.5
                            store.items[i].matrixY = 0.5
                            store.persist()
                        }
                    } else {
                        // Stayed in this quadrant — persist the new normalized position,
                        // clamped so the whole pill remains inside the quadrant border.
                        let halfW = pillSize.width / 2
                        let halfH = pillSize.height / 2
                        let pad: CGFloat = 4
                        let xMinFrac = (halfW + pad) / max(bounds.width, 1)
                        let xMaxFrac = max(xMinFrac + 0.001, (bounds.width - halfW - pad) / max(bounds.width, 1))
                        let yMinFrac = (halfH + pad) / max(bounds.height, 1)
                        let yMaxFrac = max(yMinFrac + 0.001, (bounds.height - halfH - pad) / max(bounds.height, 1))

                        let newX = clamp(finalX / bounds.width, xMinFrac, xMaxFrac)
                        let newY = clamp(finalY / bounds.height, yMinFrac, yMaxFrac)
                        withAnimation(.spring(duration: 0.25)) {
                            position = CGPoint(x: newX * bounds.width, y: newY * bounds.height)
                        }
                        store.items[i].matrixX = newX
                        store.items[i].matrixY = newY
                        store.persist()
                    }
                }
        )
        .onTapGesture { onTap() }
        .onAppear {
            // Seed from the parent-resolved (collision-free) position.
            position = initialPosition == .zero
                ? CGPoint(
                    x: (item.matrixX ?? 0.5) * bounds.width,
                    y: (item.matrixY ?? 0.5) * bounds.height
                )
                : initialPosition
        }
        .animation(.spring(duration: 0.2), value: isDragging)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }

    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Marquee Text

/// A single-line text view that:
///  • Shows a `…` ellipsis when the natural text width exceeds `maxWidth`.
///  • While `isHovering` is true *and* the text is truncated, smoothly scrolls
///    horizontally so the user can read the full title without opening the task.
///
/// The marquee uses a linear, autoreversing repeat so the text glides left to
/// expose the tail, then glides back. Hover-out cancels with a short ease-out
/// back to the resting position.
struct MarqueeText: View {
    let text: String
    let font: Font
    let maxWidth: CGFloat
    let isHovering: Bool

    @State private var fullWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    /// True when the natural text width clearly exceeds the available frame.
    private var overflows: Bool { fullWidth > maxWidth + 0.5 }

    var body: some View {
        ZStack(alignment: .leading) {
            // Hidden measurer — reports the natural (unconstrained) text width.
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .hidden()
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: MarqueeTextWidthKey.self, value: g.size.width)
                    }
                )

            // Visible text — scrolls when hovering, ellipsis-truncates otherwise.
            if isHovering && overflows {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: offset)
            } else {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(width: maxWidth, alignment: .leading)
        .clipped()
        .onPreferenceChange(MarqueeTextWidthKey.self) { fullWidth = $0 }
        .onChange(of: isHovering) { _, hovering in
            updateMarquee(hovering: hovering)
        }
        .onChange(of: text) { _, _ in
            // If the title changes mid-hover, restart the animation against the new width.
            if isHovering { updateMarquee(hovering: true) }
        }
    }

    private func updateMarquee(hovering: Bool) {
        if hovering && overflows {
            // Distance to slide so the tail (plus a tiny breathing pad) becomes visible.
            let distance = fullWidth - maxWidth + 8
            // Constant pixel-per-second speed → longer titles take proportionally longer.
            let speed: Double = 28
            let duration = max(1.6, Double(distance) / speed)

            // Snap back to start instantly (no animation) before kicking off the loop.
            offset = 0
            withAnimation(
                .linear(duration: duration)
                    .delay(0.25)          // brief pause before the first slide
                    .repeatForever(autoreverses: true)
            ) {
                offset = -distance
            }
        } else {
            // Override the repeating animation with a finite ease-out back to 0.
            withAnimation(.easeOut(duration: 0.18)) {
                offset = 0
            }
        }
    }
}

private struct MarqueeTextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
