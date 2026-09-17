//
//  BuzzingFly.swift
//  FlyOnAWall
//
//  Self-contained wandering behaviour for one fly inside a bounded field.
//  When a RobotDirector is attached, the fly reports its heading and obeys
//  swat escapes and landing commands; otherwise it moves exactly as before.
//

import SwiftUI

/// Wraps a `FlyView` with organic wander movement inside `bounds`, plus a
/// generous invisible hit target so a moving fly is still easy to tap.
struct BuzzingFly: View {
    let category: FlyCategory
    /// Anchor the fly wanders around, in the parent's coordinate space.
    let home: CGPoint
    /// Rect the fly must never leave.
    let bounds: CGRect
    var size: CGFloat = 34
    /// Optional second anchor the fly drifts toward for social categories.
    var partner: CGPoint?
    /// Seed keeps each fly's path distinct but stable.
    let seed: UInt64
    var isEmphasized: Bool = false
    /// Point the fly bursts away from on entrance (the robot's swat).
    var entranceFrom: CGPoint?
    var entranceDelay: Double = 0
    /// Optional brain: enables reporting and robot commands.
    var director: RobotDirector?
    var accessibilityTitle: String
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: CGPoint = .zero
    @State private var tilt: Double = 0
    @State private var started: Bool = false
    @State private var hasEntered: Bool = false
    @State private var parked: Bool = false
    @State private var rng: WallRandom
    @State private var wanderTask: Task<Void, Never>?

    init(
        category: FlyCategory,
        home: CGPoint,
        bounds: CGRect,
        size: CGFloat = 34,
        partner: CGPoint? = nil,
        seed: UInt64,
        isEmphasized: Bool = false,
        entranceFrom: CGPoint? = nil,
        entranceDelay: Double = 0,
        director: RobotDirector? = nil,
        accessibilityTitle: String,
        onTap: @escaping () -> Void
    ) {
        self.category = category
        self.home = home
        self.bounds = bounds
        self.size = size
        self.partner = partner
        self.seed = seed
        self.isEmphasized = isEmphasized
        self.entranceFrom = entranceFrom
        self.entranceDelay = entranceDelay
        self.director = director
        self.accessibilityTitle = accessibilityTitle
        self.onTap = onTap
        _rng = State(initialValue: WallRandom(seed: seed))
        _position = State(initialValue: entranceFrom ?? home)
        _hasEntered = State(initialValue: entranceFrom == nil)
    }

    /// Hit slop: the tappable circle is much larger than the drawn fly.
    private var hitSize: CGFloat { max(size * 2.1, 52) }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Color.clear
                    .frame(width: hitSize, height: hitSize)
                    .contentShape(Circle())
                FlyView(category: category, size: size, isEmphasized: isEmphasized)
                    .rotationEffect(.degrees(tilt))
                    .scaleEffect(isEmphasized ? 1.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isEmphasized)
            }
        }
        .buttonStyle(.plain)
        .position(position)
        .opacity(hasEntered ? 1 : 0.25)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(.isButton)
        .task { await runLife() }
    }

    // MARK: - Life

    private func runLife() async {
        guard !started else { return }
        started = true
        let inbox = director?.register(seed: seed, category: category)
        await runEntrance()
        wanderTask = Task { await runWander() }
        guard let inbox else { return }
        for await command in inbox {
            handle(command)
        }
        wanderTask?.cancel()
    }

    /// Flies burst away from the swat, then settle onto their home point.
    private func runEntrance() async {
        if entranceFrom != nil, !hasEntered, !reduceMotion {
            try? await Task.sleep(for: .seconds(entranceDelay))
            let settle = Double.random(in: 0.55...0.95)
            withAnimation(.spring(response: settle, dampingFraction: 0.62)) {
                position = home
                hasEntered = true
            }
            try? await Task.sleep(for: .seconds(settle))
        } else {
            position = home
            hasEntered = true
            try? await Task.sleep(for: .seconds(Double.random(in: 0...0.9)))
        }
        director?.report(seed: seed, position: position)
    }

    private func runWander() async {
        while !Task.isCancelled {
            if parked {
                try? await Task.sleep(for: .seconds(0.15))
                continue
            }
            let motion = category.motion
            let paused = rng.nextUnit() < motion.pauseChance
            let baseDuration = rng.next(in: motion.stepDuration)
            let duration = reduceMotion ? baseDuration * 2.2 : baseDuration
            let hold = paused ? rng.next(in: 0.4...1.3) : 0
            let target = nextTarget()
            let nextTilt = reduceMotion ? 0 : rng.next(in: -motion.wobble...motion.wobble)

            if hold > 0 {
                try? await Task.sleep(for: .seconds(hold))
            }
            withAnimation(.easeInOut(duration: duration)) {
                position = target
                tilt = nextTilt
            }
            director?.report(seed: seed, position: target)
            try? await Task.sleep(for: .seconds(duration))
        }
    }

    private func handle(_ command: FlyCommand) {
        switch command {
        case .escape(let origin): escape(from: origin)
        case .land(let point): land(at: point)
        }
    }

    /// Swat reaction: dart away fast, then resume normal wandering. The fly is
    /// never destroyed — it just wants no trouble.
    private func escape(from origin: CGPoint) {
        wanderTask?.cancel()
        parked = false
        let dx = position.x - origin.x
        let dy = position.y - origin.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let distance = Double.random(in: 105...150)
        let target = clampedToField(CGPoint(
            x: position.x + CGFloat(dx / length * distance),
            y: position.y + CGFloat(dy / length * distance)
        ))
        withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
            position = target
            tilt = Double.random(in: -22...22)
        }
        wanderTask = Task {
            try? await Task.sleep(for: .seconds(0.6))
            await runWander()
        }
    }

    /// Landing gag: sit still on the perch until the swat comes.
    private func land(at point: CGPoint) {
        wanderTask?.cancel()
        parked = true
        withAnimation(.easeInOut(duration: 1.15)) {
            position = point
            tilt = 0
        }
    }

    // MARK: - Geometry

    private func nextTarget() -> CGPoint {
        let motion = category.motion
        // Reduce Motion: tiny drift, still alive but calm.
        let radius = reduceMotion ? min(motion.radius * 0.18, 8) : motion.radius

        var anchor = home
        if let partner, !reduceMotion, rng.nextUnit() < motion.socialChance {
            anchor = CGPoint(x: (home.x + partner.x) / 2, y: (home.y + partner.y) / 2)
        }

        let angle = rng.next(in: 0...(2 * .pi))
        let distance = rng.next(in: Double(radius) * 0.35...Double(radius))
        let raw = CGPoint(
            x: anchor.x + CGFloat(cos(angle) * distance),
            y: anchor.y + CGFloat(sin(angle) * distance)
        )
        return clampedToField(raw)
    }

    private func clampedToField(_ point: CGPoint) -> CGPoint {
        let inset = hitSize / 2
        let minX = bounds.minX + inset
        let maxX = max(minX, bounds.maxX - inset)
        let minY = bounds.minY + inset
        let maxY = max(minY, bounds.maxY - inset)
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }
}
