//
//  StoryFly.swift
//  FlyOnAWall
//

import Foundation

/// A single anonymous confession, represented on the wall as one robotic fly.
///
/// Fields are deliberately wider than Phase 1 needs so a real data service can
/// populate them later without changing the UI layer.
struct StoryFly: Identifiable, Hashable, Codable {
    let id: String
    /// Anonymous public handle, e.g. "Fly #2291".
    let handle: String
    let text: String
    let category: FlyCategory
    let postedAt: Date
    var reactionCount: Int
    var witnessCount: Int
    var connectedFlyCount: Int
    var isFollowed: Bool
    /// Broad, non-precise area label. No location services in Phase 1.
    let area: String?
    /// Swarm this fly belongs to, if any.
    let swarmID: String?
    /// 0...1 strength of overlap with other flies.
    let connectionStrength: Double
    /// True when the fly was posted locally during this session.
    var isMine: Bool

    init(
        id: String = UUID().uuidString,
        handle: String,
        text: String,
        category: FlyCategory,
        postedAt: Date,
        reactionCount: Int = 0,
        witnessCount: Int = 0,
        connectedFlyCount: Int = 0,
        isFollowed: Bool = false,
        area: String? = nil,
        swarmID: String? = nil,
        connectionStrength: Double = 0,
        isMine: Bool = false
    ) {
        self.id = id
        self.handle = handle
        self.text = text
        self.category = category
        self.postedAt = postedAt
        self.reactionCount = reactionCount
        self.witnessCount = witnessCount
        self.connectedFlyCount = connectedFlyCount
        self.isFollowed = isFollowed
        self.area = area
        self.swarmID = swarmID
        self.connectionStrength = connectionStrength
        self.isMine = isMine
    }

    /// "3 hours ago" style stamp used across the app.
    var postedAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: postedAt, relativeTo: .now)
    }

    /// Copy of this fly assigned to (or removed from) a swarm. Used when a
    /// user-formed connection graph grows into a Swarm.
    func joining(swarmID: String?) -> StoryFly {
        StoryFly(
            id: id,
            handle: handle,
            text: text,
            category: category,
            postedAt: postedAt,
            reactionCount: reactionCount,
            witnessCount: witnessCount,
            connectedFlyCount: connectedFlyCount,
            isFollowed: isFollowed,
            area: area,
            swarmID: swarmID,
            connectionStrength: connectionStrength,
            isMine: isMine
        )
    }
}

/// A group of flies that appear to circle the same event.
struct Swarm: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let teaser: String
    let storyIDs: [String]
    /// Dominant categories in the swarm, used for the fly cluster preview.
    let categories: [FlyCategory]

    var flyCount: Int { storyIDs.count }
}

/// How a witness says they were involved, collected by the I WAS THERE sheet.
enum WitnessAngle: String, CaseIterable, Identifiable, Codable {
    case sawIt = "I saw it happen"
    case involved = "I was involved"
    case otherSide = "I heard another side"
    case whatHappenedNext = "I know what happened next"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sawIt: "eye.fill"
        case .involved: "hand.raised.fill"
        case .otherSide: "ear.fill"
        case .whatHappenedNext: "arrow.turn.down.right"
        }
    }
}

/// A witness claim added during this session.
struct WitnessClaim: Identifiable, Hashable, Codable {
    let id: String
    let storyID: String
    let angle: WitnessAngle
    let note: String
    let createdAt: Date

    init(id: String = UUID().uuidString, storyID: String, angle: WitnessAngle, note: String, createdAt: Date = .now) {
        self.id = id
        self.storyID = storyID
        self.angle = angle
        self.note = note
        self.createdAt = createdAt
    }
}
