//
//  FlyCategory.swift
//  FlyOnAWall
//

import SwiftUI

/// Wing silhouettes give each category a shape cue on top of its colour.
enum WingStyle: String, Hashable, Codable {
    case round
    case jagged
    case narrow
    case tattered
    case double
    case long
}

/// Movement personality for a category of flies.
struct FlyMotionProfile: Hashable, Codable {
    /// How long a single wander leg takes.
    var stepDuration: ClosedRange<Double>
    /// Wander radius in points around the fly's home point.
    var radius: CGFloat
    /// Probability of a hover pause between legs.
    var pauseChance: Double
    /// Probability of drifting toward a partner fly instead of a random point.
    var socialChance: Double
    /// Extra rotation wobble, in degrees.
    var wobble: Double
    /// Wing beat period.
    var wingBeat: Double
    /// Pulsing glow halo.
    var pulses: Bool
    /// Leaves a lagging after-image trail.
    var trails: Bool
}

/// The eight fly types. Colour plus a second cue (symbol, wings, motion, glow).
enum FlyCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case new
    case hot
    case local
    case inQuestion
    case connected
    case iWasThere
    case strongConnection
    case oldBuzz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "NEW"
        case .hot: "HOT"
        case .local: "LOCAL"
        case .inQuestion: "IN QUESTION"
        case .connected: "CONNECTED"
        case .iWasThere: "I WAS THERE"
        case .strongConnection: "STRONG CONNECTION"
        case .oldBuzz: "OLD BUZZ"
        }
    }

    /// Short line used on the legend and category banners.
    var blurb: String {
        switch self {
        case .new: "Fresh off the wall. Still sticky."
        case .hot: "Everybody is buzzing about these."
        case .local: "Buzzing around your corner of the world."
        case .inQuestion: "Stories where the details do not line up."
        case .connected: "This fly touches other flies."
        case .iWasThere: "Somebody else saw it happen."
        case .strongConnection: "Several stories overlap on the same night."
        case .oldBuzz: "Old stories that started buzzing again."
        }
    }

    var tint: Color {
        switch self {
        case .new: Color(red: 0.247, green: 0.639, blue: 0.290)
        case .hot: Color(red: 0.839, green: 0.216, blue: 0.165)
        case .local: Color(red: 0.180, green: 0.435, blue: 0.710)
        case .inQuestion: Color(red: 0.902, green: 0.663, blue: 0.145)
        case .connected: Color(red: 0.494, green: 0.294, blue: 0.749)
        case .iWasThere: Color(red: 0.827, green: 0.373, blue: 0.106)
        case .strongConnection: Color(red: 0.937, green: 0.929, blue: 0.898)
        case .oldBuzz: Color(red: 0.204, green: 0.196, blue: 0.180)
        }
    }

    /// Colour used for the glowing eyes / halo.
    var glow: Color {
        switch self {
        case .strongConnection: Color(red: 0.55, green: 0.82, blue: 0.85)
        case .oldBuzz: Color(red: 0.62, green: 0.58, blue: 0.45)
        default: tint
        }
    }

    /// Secondary non-colour cue stamped on the fly's back.
    var symbol: String {
        switch self {
        case .new: "sparkle"
        case .hot: "flame.fill"
        case .local: "mappin"
        case .inQuestion: "questionmark"
        case .connected: "link"
        case .iWasThere: "eye.fill"
        case .strongConnection: "circle.hexagongrid.fill"
        case .oldBuzz: "clock.fill"
        }
    }

    var wing: WingStyle {
        switch self {
        case .new: .round
        case .hot: .jagged
        case .local: .narrow
        case .inQuestion: .tattered
        case .connected: .double
        case .iWasThere: .long
        case .strongConnection: .round
        case .oldBuzz: .tattered
        }
    }

    var motion: FlyMotionProfile {
        switch self {
        case .new:
            FlyMotionProfile(stepDuration: 1.6...2.6, radius: 40, pauseChance: 0.25, socialChance: 0,
                             wobble: 5, wingBeat: 0.10, pulses: false, trails: false)
        case .hot:
            FlyMotionProfile(stepDuration: 0.7...1.2, radius: 52, pauseChance: 0.06, socialChance: 0,
                             wobble: 9, wingBeat: 0.06, pulses: true, trails: true)
        case .local:
            FlyMotionProfile(stepDuration: 1.8...2.8, radius: 34, pauseChance: 0.30, socialChance: 0,
                             wobble: 4, wingBeat: 0.11, pulses: false, trails: false)
        case .inQuestion:
            FlyMotionProfile(stepDuration: 0.5...1.0, radius: 46, pauseChance: 0.34, socialChance: 0,
                             wobble: 16, wingBeat: 0.07, pulses: false, trails: false)
        case .connected:
            FlyMotionProfile(stepDuration: 1.4...2.2, radius: 44, pauseChance: 0.14, socialChance: 0.35,
                             wobble: 6, wingBeat: 0.09, pulses: false, trails: true)
        case .iWasThere:
            FlyMotionProfile(stepDuration: 0.9...1.5, radius: 54, pauseChance: 0.10, socialChance: 0.45,
                             wobble: 10, wingBeat: 0.07, pulses: true, trails: true)
        case .strongConnection:
            FlyMotionProfile(stepDuration: 2.2...3.2, radius: 38, pauseChance: 0.12, socialChance: 0.2,
                             wobble: 2, wingBeat: 0.12, pulses: true, trails: false)
        case .oldBuzz:
            FlyMotionProfile(stepDuration: 3.0...4.4, radius: 30, pauseChance: 0.45, socialChance: 0,
                             wobble: 3, wingBeat: 0.18, pulses: false, trails: false)
        }
    }

    /// How the movement reads in plain words, shown in the legend.
    var motionNote: String {
        switch self {
        case .new: "wanders"
        case .hot: "fast, glowing"
        case .local: "hangs near the wall"
        case .inQuestion: "twitchy"
        case .connected: "drifts to other flies"
        case .iWasThere: "darts, trails light"
        case .strongConnection: "smooth, steady halo"
        case .oldBuzz: "slow and lazy"
        }
    }
}
