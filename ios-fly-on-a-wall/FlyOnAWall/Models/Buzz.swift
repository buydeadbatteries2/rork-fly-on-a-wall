//
//  Buzz.swift
//  FlyOnAWall
//
//  A Buzz is CONTENT: a post, story, gossip or confession published by a Fly.
//  Fields are deliberately wide so a real service can populate them later
//  without changing the UI layer.
//

import Foundation

/// One published Buzz on The Wall.
struct Buzz: Identifiable, Hashable, Codable {
    let id: String
    /// The Fly who published it.
    let authorID: String
    /// Denormalized for cheap display in replies and rows.
    let authorUsername: String
    let text: String
    /// ONE primary content category.
    let category: BuzzCategory
    /// Up to three optional tags, e.g. "#Spotted".
    let tags: [String]
    let postedAt: Date
    var reactionCount: Int
    var buzzBackCount: Int
    var iWasThereCount: Int
    var viewCount: Int
    var connectionCount: Int
    /// Broad, non-precise area label. No location services.
    let area: String?
    /// Swarm this Buzz belongs to, if any.
    let swarmID: String?
    /// 0...1 strength of overlap with other Buzzes (legacy heuristic).
    let connectionStrength: Double
    /// True when the Buzz was posted locally during this session.
    var isMine: Bool

    init(
        id: String = UUID().uuidString,
        authorID: String,
        authorUsername: String,
        text: String,
        category: BuzzCategory,
        tags: [String] = [],
        postedAt: Date,
        reactionCount: Int = 0,
        buzzBackCount: Int = 0,
        iWasThereCount: Int = 0,
        viewCount: Int = 0,
        connectionCount: Int = 0,
        area: String? = nil,
        swarmID: String? = nil,
        connectionStrength: Double = 0,
        isMine: Bool = false
    ) {
        self.id = id
        self.authorID = authorID
        self.authorUsername = authorUsername
        self.text = text
        self.category = category
        self.tags = tags
        self.postedAt = postedAt
        self.reactionCount = reactionCount
        self.buzzBackCount = buzzBackCount
        self.iWasThereCount = iWasThereCount
        self.viewCount = viewCount
        self.connectionCount = connectionCount
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

    /// Copy of this Buzz assigned to (or removed from) a swarm. Used when a
    /// user-formed connection graph grows into a Swarm.
    func joining(swarmID: String?) -> Buzz {
        Buzz(
            id: id,
            authorID: authorID,
            authorUsername: authorUsername,
            text: text,
            category: category,
            tags: tags,
            postedAt: postedAt,
            reactionCount: reactionCount,
            buzzBackCount: buzzBackCount,
            iWasThereCount: iWasThereCount,
            viewCount: viewCount,
            connectionCount: connectionCount,
            area: area,
            swarmID: swarmID,
            connectionStrength: connectionStrength,
            isMine: isMine
        )
    }
}

/// A normal reply to a Buzz. Deliberately NOT a witness claim — that is
/// I WAS THERE. Buzz Back means ordinary discussion and reactions.
struct BuzzBack: Identifiable, Hashable, Codable {
    let id: String
    let buzzID: String
    let authorID: String
    let authorUsername: String
    let text: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        buzzID: String,
        authorID: String,
        authorUsername: String,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.buzzID = buzzID
        self.authorID = authorID
        self.authorUsername = authorUsername
        self.text = text
        self.createdAt = createdAt
    }

    var postedAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: .now)
    }
}

/// A group of Flies circling the same developing story or topic.
struct Swarm: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let teaser: String
    let buzzIDs: [String]
    /// Distinct participating Flies, derived from the member Buzzes.
    let authorIDs: [String]

    var buzzCount: Int { buzzIDs.count }
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

/// A witness claim added during this session, attributed to a Fly.
struct WitnessClaim: Identifiable, Hashable, Codable {
    let id: String
    let buzzID: String
    let authorID: String
    let authorUsername: String
    let angle: WitnessAngle
    let note: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        buzzID: String,
        authorID: String,
        authorUsername: String,
        angle: WitnessAngle,
        note: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.buzzID = buzzID
        self.authorID = authorID
        self.authorUsername = authorUsername
        self.angle = angle
        self.note = note
        self.createdAt = createdAt
    }
}
