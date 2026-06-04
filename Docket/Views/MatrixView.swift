// MatrixView.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// Eisenhower Matrix view with free-positioned, draggable task pills.
///
/// Design notes:
///  • Quadrants use ultra-subtle tinted fills + hairline borders for a quiet,
///    professional feel — colour identifies, doesn't shout.
///  • Pills truncate text natively via SwiftUI; on hover, long titles scroll
///    horizontally so the full text becomes readable without opening the task.
///  • Pills cannot fully overlap — a per-quadrant rect-overlap resolver
///    spirals later pills outward until they no longer intersect.
///  • Pills are clamped to stay fully inside the quadrant border, derived
///    from the real pill geometry (label length × line count).
///  • Cross-quadrant drags preserve the perpendicular axis so pills feel
///    like they slid across the boundary.
///  • Bottom-row pills can be dragged out of the matrix to remove their
///    quadrant assignment (return to "Unassigned").
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

                // Empty-state hint — only shown when the quadrant has no pills.
                if tasks.isEmpty {
                    Text("Drop tasks here")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(color.opacity(0.45))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }

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
                        .background(Capsule().fill(color.opacity(0.14)))
                        .position(x: geo.size.width - 16, y: 13)
                }

                // Tasks — positions resolved by parent so they never fully overlap.
                ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, item in
                    TaskDot(
                        item: item,
                        quadrant: quadrant,
                        color: color,
                        maxChars: matrixLabelLength,
                        lineCount: matrixLineCount,
                        bounds: geo.size,
                        initialPosition: resolved[idx],
                        onTap: { path.append(.detail(item)) }
                    )
                }
            }
            .dropDestination(for: String.self) { items, _ in
                for idString in items {
                    if let uuid = UUID(uuidString: idString) {
                        // No withAnimation — the target view is freshly created
                        // and its seedPosition would otherwise animate from
                        // .zero (the top-left corner) under an active transaction.
                        store.mutate(uuid) { item in
                            item.quadrant = quadrant
                            item.matrixX = 0.5
                            item.matrixY = 0.5
                        }
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
        let rawTextWidth = max(36, CGFloat(maxChars) * 5.6)
        let textCap = max(20, containerWidth - 26 - 8)
        let textWidth = min(rawTextWidth, textCap)
        let lineHeight: CGFloat = 13
        return CGSize(
            width: textWidth + 26,                       // text + dot(5) + spacing(5) + 2*hPad(8)
            height: CGFloat(lineCount) * lineHeight + 9  // text height + 2*vPad(4.5)
        )
    }

    /// Compute on-screen positions for the given tasks using rectangle-overlap
    /// detection. Pills are spiralled outward by small, deterministic increments
    /// until their bounding box no longer intersects any previously placed pill.
    /// Bounds are derived from the actual pill size so no pill overflows the
    /// quadrant border.
    private func resolvePositions(for tasks: [TodoItem], in size: CGSize) -> [CGPoint] {
        guard size.width > 0, size.height > 0 else {
            return Array(repeating: .zero, count: tasks.count)
        }

        let pill = Self.pillSize(maxChars: matrixLabelLength, lineCount: matrixLineCount, in: size.width)
        let pad: CGFloat = 4
        let xMin = pill.width / 2 + pad
        let xMax = max(xMin + 1, size.width - pill.width / 2 - pad)
        let yMin = pill.height / 2 + pad
        let yMax = max(yMin + 1, size.height - pill.height / 2 - pad)

        // Inflate rects by 2pt before intersection-testing so pills never visually touch.
        let inflate: CGFloat = 2

        func rectAt(_ p: CGPoint) -> CGRect {
            CGRect(
                x: p.x - pill.width / 2 - inflate,
                y: p.y - pill.height / 2 - inflate,
                width: pill.width + inflate * 2,
                height: pill.height + inflate * 2
            )
        }

        var placed: [CGRect] = []
        var positions: [CGPoint] = []
        positions.reserveCapacity(tasks.count)

        for item in tasks {
            let baseX = (item.matrixX ?? 0.5) * size.width
            let baseY = (item.matrixY ?? 0.5) * size.height
            var p = clampPoint(CGPoint(x: baseX, y: baseY),
                               xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)

            var attempt = 0
            while attempt < 32 && placed.contains(where: { rectAt(p).intersects($0) }) {
                attempt += 1
                let angle = Double(attempt) * 1.92
                let radius = 14.0 + Double(attempt) * 5.0
                p = clampPoint(
                    CGPoint(x: baseX + CGFloat(cos(angle) * radius),
                            y: baseY + CGFloat(sin(angle) * radius)),
                    xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax
                )
            }

            placed.append(rectAt(p))
            positions.append(p)
        }
        return positions
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
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("UNASSIGNED")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if !unassigned.isEmpty {
                    Text("\(unassigned.count)")
                        .font(.system(size: 9, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)

            if unassigned.isEmpty {
                // Empty drop zone — clearly a target for clearing a quadrant assignment.
                HStack {
                    Spacer()
                    Text("Drag a pill here to remove it from the matrix")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            .quaternary,
                            style: StrokeStyle(lineWidth: 0.75, dash: [3, 3])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.quaternary.opacity(0.18))
                        )
                )
                .padding(.horizontal, 16)
            } else {
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
        }
        .padding(.vertical, 12)
        // Drop here from a quadrant to clear its assignment. Active in both
        // empty and populated states.
        .dropDestination(for: String.self) { items, _ in
            for idString in items {
                if let uuid = UUID(uuidString: idString) {
                    // No withAnimation — see note in quadrantBox.dropDestination.
                    store.mutate(uuid) { item in
                        item.quadrant = nil
                        item.matrixX = nil
                        item.matrixY = nil
                    }
                }
            }
            return true
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
/// top of each other. The pill also re-seats itself when the parent recomputes
/// positions (e.g., after a window resize or a setting change).
struct TaskDot: View {
    let item: TodoItem
    let quadrant: Quadrant
    let color: Color
    let maxChars: Int
    let lineCount: Int
    let bounds: CGSize
    /// `nil` = position not yet computed by the parent (use stored matrixX/Y).
    let initialPosition: CGPoint?
    let onTap: () -> Void

    /// Pill centre, in source-quadrant local coordinates.
    @State private var position: CGPoint = .zero
    /// Pill centre at the moment the current drag started — anchor for translation deltas.
    @State private var dragStartPosition: CGPoint?
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var dragMaxDistance: CGFloat = 0

    /// Width budget for the title text. Capped to the available container so
    /// the pill itself never exceeds the quadrant box.
    private var textMaxWidth: CGFloat {
        let raw = max(36, CGFloat(maxChars) * 5.6)
        let cap = max(20, bounds.width - 26 - 8)
        return min(raw, cap)
    }

    /// Real on-screen size of this pill.
    private var pillSize: CGSize {
        MatrixView.pillSize(maxChars: maxChars, lineCount: lineCount, in: bounds.width)
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Group {
                if lineCount == 1 {
                    // Single-line: marquee scrolls on hover when truncated.
                    // Suppress while dragging so the title doesn't slide under the cursor.
                    MarqueeText(
                        text: item.title,
                        font: .system(size: 10, weight: .medium),
                        maxWidth: textMaxWidth,
                        isHovering: isHovering && !isDragging
                    )
                } else {
                    Text(item.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(lineCount)
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
        // Implicit animation scope MUST come before .position so cursor-following
        // updates aren't subjected to a spring (which would feel like the pill is
        // lagging or "falling" toward the cursor).
        .animation(.spring(duration: 0.2), value: isDragging)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .position(x: position.x, y: position.y)
        .zIndex(isDragging ? 10 : (isHovering ? 5 : 0))
        .onHover { isHovering = $0 }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let dist = hypot(value.translation.width, value.translation.height)
                    if dist > dragMaxDistance { dragMaxDistance = dist }

                    // Only enter "drag mode" once the cursor has moved a few
                    // points — keeps a still click from triggering a scale-up
                    // flicker, and gives the tap-vs-drag check headroom.
                    if !isDragging && dist >= 3 {
                        dragStartPosition = position
                        isDragging = true
                    }

                    if isDragging, let start = dragStartPosition {
                        position = CGPoint(
                            x: start.x + value.translation.width,
                            y: start.y + value.translation.height
                        )
                    }
                }
                .onEnded { value in
                    let totalDistance = dragMaxDistance
                    dragMaxDistance = 0

                    // Treat micro-movements as taps (avoids opening the detail
                    // view when the user wiggles the cursor while clicking).
                    if totalDistance < 4 {
                        isDragging = false
                        dragStartPosition = nil
                        onTap()
                        return
                    }

                    handleDragEnd(value: value)
                    isDragging = false
                    dragStartPosition = nil
                }
        )
        // Re-seat when the parent recomputes layout (resize, settings change,
        // or a sibling pill moved and our resolved spot shifted).
        // Skipped while dragging so the cursor-follow isn't fought.
        .onChange(of: initialPosition) { _, new in
            guard !isDragging, let new else { return }
            withAnimation(.smooth(duration: 0.25)) { position = new }
        }
        .onAppear {
            // Always seed the position outside any active animation transaction.
            // When this TaskDot is freshly created (e.g. as a result of a
            // cross-quadrant move), the parent's mutate may have been wrapped
            // in withAnimation — without this guard, SwiftUI would animate
            // `position` from its default .zero (top-left corner) to the
            // resolved spot, which reads as the pill "dropping from the top".
            withTransaction(Transaction(animation: nil)) {
                seedPosition()
            }
        }
    }

    // MARK: - Drag end

    private func handleDragEnd(value: DragGesture.Value) {
        // Use predicted translation so a quick flick still carries through to
        // the adjacent quadrant — the actual translation can stop just shy of
        // the boundary if the user releases at peak velocity.
        guard let start = dragStartPosition else { return }
        let predicted = value.predictedEndTranslation
        let actual = value.translation

        // Cross-over decision uses the predicted endpoint (intent-aware).
        let predictedX = start.x + predicted.width
        let predictedY = start.y + predicted.height

        let crossedLeft   = predictedX < 0
        let crossedRight  = predictedX > bounds.width
        let crossedTop    = predictedY < 0
        let crossedBottom = predictedY > bounds.height

        if crossedLeft || crossedRight || crossedTop || crossedBottom {
            // Bottom-row sources can drop "off the bottom" to return to Unassigned.
            let isBottomRow = quadrant == .delegate || quadrant == .eliminate
            let droppedFarBelow = crossedBottom && predictedY > bounds.height + 50

            if isBottomRow && droppedFarBelow {
                // Cross-container move (this TaskDot is about to be destroyed
                // and re-created in the unassigned strip). No withAnimation
                // wrapper — otherwise the new view's onAppear seeds its
                // position inside the active transaction and SwiftUI
                // animates it in from .zero (the top-left corner).
                Store.shared.mutate(item.id) { item in
                    item.quadrant = nil
                    item.matrixX = nil
                    item.matrixY = nil
                }
                return
            }

            let target: Quadrant? = switch quadrant {
            case .doFirst:   crossedRight ? .schedule  : crossedBottom ? .delegate  : nil
            case .schedule:  crossedLeft  ? .doFirst   : crossedBottom ? .eliminate : nil
            case .delegate:  crossedRight ? .eliminate : crossedTop    ? .doFirst   : nil
            case .eliminate: crossedLeft  ? .delegate  : crossedTop    ? .schedule  : nil
            }

            guard let target else {
                // Diagonal exit (no matching neighbour) — settle back inside.
                settleInside(actualX: start.x + actual.width, actualY: start.y + actual.height)
                return
            }

            let (newX, newY) = entryPoint(into: target, finalX: predictedX, finalY: predictedY)
            // Cross-quadrant move — no withAnimation wrapper (see note above).
            Store.shared.mutate(item.id) { item in
                item.quadrant = target
                item.matrixX = newX
                item.matrixY = newY
            }
        } else {
            // Stayed inside — settle the pill to the actual cursor position
            // (clamped to keep the whole pill within the quadrant border).
            settleInside(actualX: start.x + actual.width, actualY: start.y + actual.height)
        }
    }

    /// Persist a new in-quadrant position and animate the pill to it. Uses
    /// `.smooth` (critically damped) so there's no spring overshoot — the
    /// pill simply eases into its final resting place.
    private func settleInside(actualX: CGFloat, actualY: CGFloat) {
        let halfW = pillSize.width / 2
        let halfH = pillSize.height / 2
        let pad: CGFloat = 4
        let xMinFrac = (halfW + pad) / max(bounds.width, 1)
        let xMaxFrac = max(xMinFrac + 0.001, (bounds.width - halfW - pad) / max(bounds.width, 1))
        let yMinFrac = (halfH + pad) / max(bounds.height, 1)
        let yMaxFrac = max(yMinFrac + 0.001, (bounds.height - halfH - pad) / max(bounds.height, 1))

        let newX = clamp(actualX / bounds.width, xMinFrac, xMaxFrac)
        let newY = clamp(actualY / bounds.height, yMinFrac, yMaxFrac)
        let target = CGPoint(x: newX * bounds.width, y: newY * bounds.height)

        withAnimation(.smooth(duration: 0.22)) {
            position = target
        }
        Store.shared.mutate(item.id) { item in
            item.matrixX = newX
            item.matrixY = newY
        }
    }

    /// Compute the (matrixX, matrixY) the pill should land at when entering
    /// `target` from the given exit-edge coordinates. Preserves the
    /// perpendicular axis so the pill feels like it slid across the boundary.
    private func entryPoint(into target: Quadrant, finalX: CGFloat, finalY: CGFloat) -> (Double, Double) {
        let xRatio = clamp(finalX / bounds.width, 0.15, 0.85)
        let yRatio = clamp(finalY / bounds.height, 0.15, 0.85)

        // Determine the entry edge from source→target geometry.
        switch (quadrant, target) {
        case (.doFirst, .schedule), (.delegate, .eliminate):
            // Exited right edge of source → enter left edge of target.
            return (0.18, yRatio)
        case (.schedule, .doFirst), (.eliminate, .delegate):
            // Exited left → enter right.
            return (0.82, yRatio)
        case (.doFirst, .delegate), (.schedule, .eliminate):
            // Exited bottom → enter top.
            return (xRatio, 0.20)
        case (.delegate, .doFirst), (.eliminate, .schedule):
            // Exited top → enter bottom.
            return (xRatio, 0.80)
        default:
            return (0.5, 0.5)
        }
    }

    // MARK: - Position seeding

    private func seedPosition() {
        if let p = initialPosition {
            position = p
        } else {
            position = CGPoint(
                x: (item.matrixX ?? 0.5) * bounds.width,
                y: (item.matrixY ?? 0.5) * bounds.height
            )
        }
    }

    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private func clamp(_ value: CGFloat, _ min: CGFloat, _ max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Marquee Text

/// A single-line text view that:
///  • Shows a `…` ellipsis when the natural text width exceeds `maxWidth`.
///  • While `isHovering` is true *and* the text is truncated, smoothly scrolls
///    horizontally so the user can read the full title without opening the task.
struct MarqueeText: View {
    let text: String
    let font: Font
    let maxWidth: CGFloat
    let isHovering: Bool

    @State private var fullWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

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
            if isHovering { updateMarquee(hovering: true) }
        }
    }

    private func updateMarquee(hovering: Bool) {
        if hovering && overflows {
            let distance = fullWidth - maxWidth + 8
            let speed: Double = 28
            let duration = max(1.6, Double(distance) / speed)
            offset = 0
            withAnimation(
                .linear(duration: duration)
                    .delay(0.25)
                    .repeatForever(autoreverses: true)
            ) {
                offset = -distance
            }
        } else {
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
