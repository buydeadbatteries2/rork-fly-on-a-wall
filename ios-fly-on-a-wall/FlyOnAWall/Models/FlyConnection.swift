//
//  FlyConnection.swift
//  FlyOnAWall
//
//  Phase 2 connection model: STORIES that may describe the same situation.
//  Connections always relate stories, never people — the language everywhere is
//  "these flies may connect", never identification.
//

import Foundation

/// How strongly two stories appear to overlap. Describes similarity between
/// story details only — it never confirms identities or facts.
enum ConnectionStrength: String, CaseIterable, Codable, Hashable {
    case weakBuzz
    case possible
    case strongBuzz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weakBuzz: "WEAK BUZZ"
        case .possible: "POSSIBLE CONNECTION"
        case .strongBuzz: "STRONG BUZZ"
        }
    }

    /// One-line meaning, shown on the board legend and clue sheets.
    var blurb: String {
        switch self {
        case .weakBuzz: "Some details overlap, but the connection is uncertain."
        case .possible: "Several details overlap."
        case .strongBuzz: "Multiple meaningful story details overlap."
        }
    }

    /// Safety language shown for stronger connections.
    var safetyLine: String? {
        switch self {
        case .strongBuzz:
            "Strong Buzz means these stories contain significant overlapping details. It does not confirm the identities of anyone involved."
        case .possible:
            "These stories may describe the same situation. No person is being identified."
        case .weakBuzz:
            nil
        }
    }
}

/// What a user says two stories share. Multiple selections allowed.
enum ConnectionClue: String, CaseIterable, Codable, Hashable, Identifiable {
    case sameEventType = "Same type of event"
    case sameTimeframe = "Same general timeframe"
    case similarSetting = "Similar location/setting"
    case detailsOverlap = "Story details overlap"
    case iWasThere = "I was there"
    case somethingElse = "Something else"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sameEventType: "tag.fill"
        case .sameTimeframe: "clock.fill"
        case .similarSetting: "mappin"
        case .detailsOverlap: "text.alignleft"
        case .iWasThere: "eye.fill"
        case .somethingElse: "sparkle"
        }
    }

    /// Weight in the local analyzer. Independent, specific clues score higher.
    var weight: Double {
        switch self {
        case .detailsOverlap: 1.5
        case .sameTimeframe: 1.2
        case .sameEventType: 1.0
        case .similarSetting: 1.0
        case .iWasThere: 1.0
        case .somethingElse: 0.3
        }
    }
}

/// One proposed or suggested link between two story flies.
struct FlyConnection: Identifiable, Hashable, Codable {
    let id: String
    /// Story ID at one end of the line.
    let sourceID: String
    /// Story ID at the other end. Order carries no meaning.
    let targetID: String
    let strength: ConnectionStrength
    let overlappingClues: [ConnectionClue]
    /// Plain-language conflicts, e.g. "One detail conflicts".
    let conflictingClues: [String]
    /// True when a user proposed this; false for system-suggested data.
    let isUserProposed: Bool
    let createdAt: Date
    /// Swarm this connection participates in, when known.
    let swarmID: String?

    init(
        id: String = UUID().uuidString,
        sourceID: String,
        targetID: String,
        strength: ConnectionStrength,
        overlappingClues: [ConnectionClue],
        conflictingClues: [String] = [],
        isUserProposed: Bool = false,
        createdAt: Date = .now,
        swarmID: String? = nil
    ) {
        self.id = id
        self.sourceID = sourceID
        self.targetID = targetID
        self.strength = strength
        self.overlappingClues = overlappingClues
        self.conflictingClues = conflictingClues
        self.isUserProposed = isUserProposed
        self.createdAt = createdAt
        self.swarmID = swarmID
    }

    func involves(_ storyID: String) -> Bool {
        sourceID == storyID || targetID == storyID
    }

    /// The ID at the other end of the line.
    func other(end storyID: String) -> String {
        sourceID == storyID ? targetID : sourceID
    }

    var bothIDs: [String] { [sourceID, targetID] }

    /// Copy of this link attached to a swarm (used when a swarm forms).
    func attached(to swarmID: String) -> FlyConnection {
        FlyConnection(
            id: id,
            sourceID: sourceID,
            targetID: targetID,
            strength: strength,
            overlappingClues: overlappingClues,
            conflictingClues: conflictingClues,
            isUserProposed: isUserProposed,
            createdAt: createdAt,
            swarmID: swarmID
        )
    }
}
