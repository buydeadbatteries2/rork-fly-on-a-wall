//
//  WallTheme.swift
//  FlyOnAWall
//
//  Sunbleached Junkyard visual system: palette, type roles, metrics.
//

import SwiftUI

/// Core palette for the sunbleached junkyard wall aesthetic.
enum WallTheme {
    /// Bone concrete canvas.
    static let bone = Color(red: 0.906, green: 0.875, blue: 0.788) // #E7DFC9
    /// Warm gray elevated surface.
    static let warmGray = Color(red: 0.725, green: 0.686, blue: 0.596) // #B9AF98
    /// Primary rust accent.
    static let rust = Color(red: 0.769, green: 0.333, blue: 0.122) // #C4551F
    /// Secondary faded teal accent.
    static let teal = Color(red: 0.247, green: 0.490, blue: 0.455) // #3F7D74
    /// Charcoal ink used for stencil lettering.
    static let ink = Color(red: 0.145, green: 0.125, blue: 0.106) // #251F1B
    /// Aged paper for scraps and posters.
    static let paper = Color(red: 0.937, green: 0.894, blue: 0.796) // #EFE4CB
    /// Muted ink for secondary copy.
    static let inkSoft = Color(red: 0.322, green: 0.286, blue: 0.239) // #52493D
}

/// Typographic roles: worn stencil titles, marker handwriting for labels.
enum WallFont {
    /// Heavy compressed uppercase, used for spray-paint titles.
    static func stencil(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default).width(.compressed)
    }

    /// Serif "marker on paper" voice for confessions and notes.
    static func marker(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Small stamped label voice.
    static func stamp(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .default).width(.compressed)
    }

    /// Clean sans-serif voice for METADATA — counts, timestamps, helper copy.
    /// Never thin: semibold keeps it legible over textured surfaces.
    static func meta(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

/// Bundled artwork names. The rusty nameplate was retired — its asset file
/// remains on disk but has zero runtime references.
enum WallAsset {
    static let wall = "urban_junkyard_wall"
    static let robotIdle = "goofy_robot_mascot"
    static let robotSwat = "robot_flyswatter_swat"
    static let paper = "torn_paper_scrap"
}

/// Shared layout metrics.
enum WallMetrics {
    /// Height of the custom tab strip, excluding the home indicator inset.
    static let tabBarHeight: CGFloat = 66
    /// Vertical clearance content must keep above the tab strip.
    static let tabBarClearance: CGFloat = 86
    static let corner: CGFloat = 14
}

/// Tiny deterministic generator so scattered layouts stay stable across redraws.
struct WallRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 2862933555777941757 &+ 3037000493
    }

    mutating func nextUnit() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextUnit() * (range.upperBound - range.lowerBound)
    }
}

extension View {
    /// Soft drop shadow tuned for objects pinned onto the bright wall.
    func wallShadow(radius: CGFloat = 8, y: CGFloat = 5) -> some View {
        shadow(color: .black.opacity(0.28), radius: radius, x: 0, y: y)
    }
}
