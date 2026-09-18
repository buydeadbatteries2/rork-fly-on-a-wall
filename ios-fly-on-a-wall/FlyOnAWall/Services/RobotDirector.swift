//
//  RobotDirector.swift
//  FlyOnAWall
//
//  The robot's brain. Runs lightweight timer loops that cycle idle personality,
//  react to flies reported by BuzzingFly, and orchestrate the rare landing gag.
//  Owns no UI: it publishes small render values that StinkyRobotView observes
//  and sends one-shot commands to individual flies.
//

import Observation
import SwiftUI

/// Facial/body expressions layered over the robot artwork.
enum RobotExpression: String, Hashable {
    case neutral
    case blink
    case annoyed
    case surprised
    case suspicious
    case skeptical
    case laughing
}

/// One-shot instructions the director can send to an individual fly.
enum FlyCommand: Sendable {
    /// Dart away from a point (a swat). The fly is never destroyed.
    case escape(from: CGPoint)
    /// Fly to a point and sit there until released.
    case land(at: CGPoint)
}

/// Drives the mascot's silent-comedy behaviour on The Wall.
@MainActor
@Observable
final class RobotDirector {
    // MARK: Render values (observed by StinkyRobotView)

    private(set) var state: RobotState = .idle
    private(set) var expression: RobotExpression = .neutral
    /// Pupil shift, roughly -1...1 per axis.
    private(set) var look: CGSize = .zero
    /// Head lean in degrees.
    private(set) var headTilt: Double = 0
    /// Whole-body micro shift in points.
    private(set) var bodyShift: CGSize = .zero
    private(set) var stinkBoost: Bool = false
    /// Increments on every swat so the screen can play ripple + haptics.
    private(set) var swatToken: Int = 0
    private(set) var isCelebrating: Bool = false

    // MARK: Scene wiring (set by TheWallScreen; not render state)

    @ObservationIgnored var reduceMotion: Bool = false
    /// Scene-space position of the robot's head, used for "who's near me".
    @ObservationIgnored var headPoint: CGPoint = .zero
    /// Scene-space perch where the landing gag fly touches down.
    @ObservationIgnored var perchPoint: CGPoint = .zero

    /// Called by The Wall on every layout pass; keeps the brain's map of its
    /// own body in sync with the robot's on-screen position.
    func syncScene(reduceMotion: Bool, head: CGPoint, perch: CGPoint) -> Void {
        self.reduceMotion = reduceMotion
        self.headPoint = head
        self.perchPoint = perch
    }

    @ObservationIgnored private var statuses: [UInt64: FlyStatus] = [:]
    @ObservationIgnored private var spots: [UInt64: CGPoint] = [:]
    @ObservationIgnored private var inboxes: [UInt64: AsyncStream<FlyCommand>.Continuation] = [:]
    @ObservationIgnored private var behaviorTask: Task<Void, Never>?
    @ObservationIgnored private var gagTask: Task<Void, Never>?
    @ObservationIgnored private var lastSwat: Date = .distantPast

    // MARK: - Lifecycle

    /// Starts the behaviour loops. Safe to call repeatedly.
    func start() {
        guard behaviorTask == nil else { return }
        behaviorTask = Task { await runBehaviorLoop() }
        gagTask = Task { await runLandingGag() }
    }

    func stop() {
        behaviorTask?.cancel()
        behaviorTask = nil
        gagTask?.cancel()
        gagTask = nil
    }

    /// The choreographed swat that opens The Wall.
    func openingSwat() {
        setExpression(.annoyed)
        state = .swat
        swatToken += 1
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.75))
            self?.state = .idle
            self?.relax()
        }
    }

    /// Brief amused reaction when the user returns after engaging a HOT fly.
    func celebrate() {
        guard state == .idle else { return }
        isCelebrating = true
        setExpression(.laughing)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.0))
            self?.isCelebrating = false
            self?.relax()
        }
    }

    // MARK: - Fly registration

    /// Flies join the director's world and receive commands via the returned stream.
    func register(seed: UInt64, status: FlyStatus) -> AsyncStream<FlyCommand> {
        statuses[seed] = status
        return AsyncStream { continuation in
            inboxes[seed] = continuation
        }
    }

    /// Flies report where they are heading. Approximate is plenty.
    func report(seed: UInt64, position: CGPoint) {
        spots[seed] = position
    }

    // MARK: - Swat

    /// Performs a swat and scares the target seed plus anything within `scareRadius`.
    func performSwat(origin: CGPoint, targetSeed: UInt64? = nil, scareRadius: CGFloat = 0) {
        lastSwat = .now
        setExpression(.annoyed)
        state = .swat
        swatToken += 1
        for (seed, spot) in spots {
            let isTarget = seed == targetSeed
            let isNearby = scareRadius > 0 && distance(from: origin, to: spot) < scareRadius
            if isTarget || isNearby {
                send(.escape(from: origin), to: seed)
            }
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            guard let self, self.state == .swat else { return }
            self.state = .idle
            self.relax()
        }
    }

    private var canIdleSwat: Bool { Date.now.timeIntervalSince(lastSwat) > 20 }

    // MARK: - Behaviour loops

    /// Long, lazy loop: mostly nothing, sometimes a personality tick, sometimes
    /// noticing a nearby fly. The robot should feel idle far more than busy.
    private func runBehaviorLoop() async {
        try? await Task.sleep(for: .seconds(3.2))
        while !Task.isCancelled {
            if Double.random(in: 0...1) < 0.6, let nearest = nearestSpot(within: 230) {
                await react(to: nearest)
            } else {
                await idleTick()
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 2.8...6.5)))
        }
    }

    private func react(to nearest: (seed: UInt64, spot: CGPoint, distance: CGFloat)) async {
        let direction = unit(from: headPoint, to: nearest.spot)

        // Occasional idle swat when a fly hassles his head.
        if nearest.distance < 125, canIdleSwat, state == .idle, Double.random(in: 0...1) < 0.3 {
            performSwat(origin: headPoint, scareRadius: 150)
            return
        }

        switch statuses[nearest.seed] {
        case .hot where Double.random(in: 0...1) < 0.55:
            glance(toward: direction, strength: 1.0)
            setExpression(.surprised)
            try? await Task.sleep(for: .seconds(Double.random(in: 0.9...1.4)))
        case .iWasThere where Double.random(in: 0...1) < 0.55:
            // "Wait... what do YOU know?" — lean in, narrow the eyes.
            glance(toward: direction, strength: 1.0)
            withAnimation(.easeInOut(duration: 0.4)) {
                headTilt = direction.width >= 0 ? 8 : -8
                bodyShift = CGSize(width: direction.width * 6, height: 1)
            }
            setExpression(.suspicious)
            try? await Task.sleep(for: .seconds(Double.random(in: 1.5...2.1)))
        case .inQuestion where Double.random(in: 0...1) < 0.5:
            // "I don't know about that one..." — squint, tilt away.
            glance(toward: direction, strength: 0.8)
            withAnimation(.easeInOut(duration: 0.4)) {
                headTilt = direction.width >= 0 ? -5 : 5
            }
            setExpression(.skeptical)
            try? await Task.sleep(for: .seconds(Double.random(in: 1.2...1.8)))
        default:
            if Double.random(in: 0...1) < 0.45 {
                glance(toward: direction, strength: 0.7)
                try? await Task.sleep(for: .seconds(Double.random(in: 1.2...1.9)))
            } else {
                await idleTick()
                return
            }
        }
        relax()
    }

    /// One small idle personality beat. Weighted so doing nothing is common.
    private func idleTick() async {
        let roll = Double.random(in: 0...1)
        if roll < 0.30 {
            return
        } else if roll < 0.55 {
            setExpression(.blink)
            try? await Task.sleep(for: .seconds(0.16))
            if Double.random(in: 0...1) < 0.25 {
                setExpression(.neutral)
                try? await Task.sleep(for: .seconds(0.14))
                setExpression(.blink)
                try? await Task.sleep(for: .seconds(0.14))
            }
        } else if roll < 0.72 {
            let side: CGFloat = Bool.random() ? 1 : -1
            withAnimation(.easeInOut(duration: 0.5)) {
                look = CGSize(width: side * 0.9, height: 0.1)
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 1.6...2.6)))
        } else if roll < 0.82, !reduceMotion {
            withAnimation(.easeInOut(duration: 0.6)) {
                headTilt = Bool.random() ? 4 : -4
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 1.8...2.6)))
        } else if roll < 0.90, !reduceMotion {
            withAnimation(.easeInOut(duration: 0.7)) {
                bodyShift = CGSize(width: Double.random(in: 4...8) * (Bool.random() ? 1 : -1), height: 0)
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 2.2...3.2)))
        } else if roll < 0.96 {
            setExpression(.annoyed)
            if Bool.random() { stinkBoost = true }
            try? await Task.sleep(for: .seconds(Double.random(in: 1.2...1.8)))
            stinkBoost = false
        } else if let nearest = nearestSpot(within: 320) {
            glance(toward: unit(from: headPoint, to: nearest.spot), strength: 0.7)
            try? await Task.sleep(for: .seconds(Double.random(in: 1.2...1.8)))
        }
        relax()
    }

    /// Rare gag: a fly lands on his head. He notices... pauses... swats.
    private func runLandingGag() async {
        try? await Task.sleep(for: .seconds(Double.random(in: 20...38)))
        while !Task.isCancelled {
            if !reduceMotion, state == .idle, let seed = statuses.keys.randomElement() {
                send(.land(at: perchPoint), to: seed)
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.easeInOut(duration: 0.35)) {
                    look = unit(from: headPoint, to: perchPoint)
                }
                setExpression(.surprised)
                try? await Task.sleep(for: .seconds(Double.random(in: 0.9...1.5)))
                performSwat(origin: perchPoint, targetSeed: seed)
                try? await Task.sleep(for: .seconds(1.1))
                relax()
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 45...85)))
        }
    }

    // MARK: - Helpers

    private func glance(toward direction: CGSize, strength: CGFloat) {
        withAnimation(.easeInOut(duration: 0.4)) {
            look = CGSize(width: direction.width * strength, height: direction.height * strength * 0.6)
        }
    }

    private func setExpression(_ newExpression: RobotExpression) {
        withAnimation(.easeInOut(duration: 0.18)) {
            expression = newExpression
        }
    }

    private func relax() {
        withAnimation(.easeInOut(duration: 0.5)) {
            look = .zero
            headTilt = 0
            bodyShift = .zero
            if expression != .laughing { expression = .neutral }
        }
    }

    private func send(_ command: FlyCommand, to seed: UInt64) {
        inboxes[seed]?.yield(command)
    }

    private func nearestSpot(within radius: CGFloat) -> (seed: UInt64, spot: CGPoint, distance: CGFloat)? {
        var best: (seed: UInt64, spot: CGPoint, distance: CGFloat)?
        for (seed, spot) in spots {
            let d = distance(from: headPoint, to: spot)
            if d < radius, best == nil || d < best!.distance {
                best = (seed, spot, d)
            }
        }
        return best
    }

    private func unit(from: CGPoint, to: CGPoint) -> CGSize {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        return CGSize(width: dx / length, height: dy / length)
    }

    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
}
