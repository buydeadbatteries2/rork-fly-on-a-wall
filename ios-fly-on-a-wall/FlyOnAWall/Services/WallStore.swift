//
//  WallStore.swift
//  FlyOnAWall
//
//  Session-local state for the blogger platform: FlyProfiles (users), their
//  Buzzes (posts), Buzz Backs, follows and story-to-story connections.
//  Everything here is in-memory mock data; a real service can replace the
//  bodies without changing any view.
//

import Foundation
import SwiftUI

@Observable
final class WallStore {
    private(set) var buzzes: [Buzz]
    private(set) var profiles: [FlyProfile]
    private(set) var swarms: [Swarm]
    private(set) var buzzBacks: [BuzzBack]
    private(set) var witnessClaims: [WitnessClaim] = []
    /// Buzzes posted during this session, newest first.
    private(set) var myBuzzIDs: [String] = []
    /// Buzz IDs the user reacted to with 😂.
    private(set) var reactedIDs: Set<String> = []
    /// Fly IDs the user follows.
    private(set) var followedFlyIDs: Set<String> = []
    /// Buzz-to-buzz links. Buzzes only — never identification of people.
    private(set) var connections: [FlyConnection] = MockWallData.connections

    /// The local profile of the person holding the phone.
    let me: FlyProfile

    init(
        buzzes: [Buzz] = MockWallData.buzzes,
        profiles: [FlyProfile] = MockWallData.profiles,
        swarms: [Swarm] = MockWallData.swarms,
        buzzBacks: [BuzzBack] = MockWallData.buzzBacks
    ) {
        self.buzzes = buzzes
        self.profiles = profiles
        self.swarms = swarms
        self.buzzBacks = buzzBacks
        self.me = profiles.first { $0.isMe } ?? FlyProfile(id: "fly-me", username: "@JustLanded", displayName: "You", tagline: "New here.")
    }

    // MARK: - Reads: content

    func buzz(id: String) -> Buzz? {
        buzzes.first { $0.id == id }
    }

    func buzzes(in category: BuzzCategory) -> [Buzz] {
        buzzes.filter { $0.category == category }
    }

    func buzzes(by authorID: String) -> [Buzz] {
        buzzes.filter { $0.authorID == authorID }
    }

    func buzzes(in swarm: Swarm) -> [Buzz] {
        swarm.buzzIDs.compactMap { id in buzzes.first { $0.id == id } }
    }

    /// The Buzz previewed for a Fly — featured first, then newest.
    func currentBuzz(for fly: FlyProfile) -> Buzz? {
        if let featured = fly.featuredBuzzID, let buzz = buzz(id: featured) { return buzz }
        return buzzes(by: fly.id).max { $0.postedAt < $1.postedAt }
    }

    // MARK: - Reads: flies

    func profile(id: String) -> FlyProfile? {
        profiles.first { $0.id == id }
    }

    /// Bloggers currently on The Wall. With a category, only Flies that
    /// currently have Buzz in that category appear.
    func flies(for category: BuzzCategory?) -> [FlyProfile] {
        let publicFlies = profiles.filter { !$0.isMe }
        guard let category else { return publicFlies }
        return publicFlies.filter { fly in
            buzzes.contains { $0.authorID == fly.id && $0.category == category }
        }
    }

    var followedFlies: [FlyProfile] {
        profiles.filter { followedFlyIDs.contains($0.id) }
    }

    var myBuzzes: [Buzz] {
        myBuzzIDs.compactMap { id in buzzes.first { $0.id == id } }
    }

    func isFollowing(_ flyID: String) -> Bool {
        followedFlyIDs.contains(flyID)
    }

    // MARK: - Reads: conversation

    func buzzBacks(for buzzID: String) -> [BuzzBack] {
        buzzBacks.filter { $0.buzzID == buzzID }.sorted { $0.createdAt > $1.createdAt }
    }

    func claims(for buzzID: String) -> [WitnessClaim] {
        witnessClaims.filter { $0.buzzID == buzzID }
    }

    var totalBuzzes: Int {
        witnessClaims.count + reactedIDs.count + myBuzzIDs.count
    }

    // MARK: - Reads: swarms

    func swarm(for buzz: Buzz) -> Swarm? {
        guard let swarmID = buzz.swarmID else { return nil }
        return swarms.first { $0.id == swarmID }
    }

    /// Distinct Flies participating in a swarm.
    func flyAuthors(for swarm: Swarm) -> [FlyProfile] {
        var ids: [String] = []
        for buzz in buzzes(in: swarm) where !ids.contains(buzz.authorID) {
            ids.append(buzz.authorID)
        }
        return ids.compactMap { profile(id: $0) }
    }

    func flyCount(for swarm: Swarm) -> Int {
        Set(buzzes(in: swarm).map(\.authorID)).count
    }

    // MARK: - Connections

    /// Every link touching a buzz, in either direction.
    func connections(touching buzzID: String) -> [FlyConnection] {
        connections.filter { $0.involves(buzzID) }
    }

    /// The link between two buzzes, if one exists.
    func connection(between buzzA: String, and buzzB: String) -> FlyConnection? {
        connections.first { $0.bothIDs.contains(buzzA) && $0.bothIDs.contains(buzzB) }
    }

    /// Other buzzes that plausibly touch this one: the connection graph first,
    /// then the legacy connection-strength heuristic for unlinked buzzes.
    func connectedBuzzes(to buzz: Buzz) -> [Buzz] {
        let linked = connections(touching: buzz.id)
            .compactMap { self.buzz(id: $0.other(end: buzz.id)) }
        if !linked.isEmpty { return linked }

        var result: [Buzz] = []
        if let swarmID = buzz.swarmID {
            result += buzzes.filter { $0.swarmID == swarmID && $0.id != buzz.id }
        }
        if result.count < 3 {
            let extras = buzzes
                .filter { $0.id != buzz.id && !result.contains($0) && $0.connectionStrength > 0.4 }
                .sorted { abs($0.connectionStrength - buzz.connectionStrength) < abs($1.connectionStrength - buzz.connectionStrength) }
                .prefix(3 - result.count)
            result += extras
        }
        return result
    }

    /// Strong / possible / weak counts for a swarm's internal connections.
    func connectionStats(for swarm: Swarm) -> (strong: Int, possible: Int, weak: Int) {
        let members = Set(swarm.buzzIDs)
        var strong = 0
        var possible = 0
        var weak = 0
        for link in connections where members.isSuperset(of: link.bothIDs) {
            switch link.strength {
            case .strongBuzz: strong += 1
            case .possible: possible += 1
            case .weakBuzz: weak += 1
            }
        }
        return (strong, possible, weak)
    }

    // MARK: - Mutations: reactions & follows

    func hasReacted(to buzzID: String) -> Bool {
        reactedIDs.contains(buzzID)
    }

    func toggleReaction(_ buzzID: String) {
        guard let index = buzzes.firstIndex(where: { $0.id == buzzID }) else { return }
        if reactedIDs.contains(buzzID) {
            reactedIDs.remove(buzzID)
            buzzes[index].reactionCount = max(0, buzzes[index].reactionCount - 1)
        } else {
            reactedIDs.insert(buzzID)
            buzzes[index].reactionCount += 1
        }
    }

    func toggleFollow(_ flyID: String) {
        guard let index = profiles.firstIndex(where: { $0.id == flyID }), !profiles[index].isMe else { return }
        if followedFlyIDs.contains(flyID) {
            followedFlyIDs.remove(flyID)
            profiles[index].followerCount = max(0, profiles[index].followerCount - 1)
            updateMe { $0.followingCount = max(0, $0.followingCount - 1) }
        } else {
            followedFlyIDs.insert(flyID)
            profiles[index].followerCount += 1
            updateMe { $0.followingCount += 1 }
        }
    }

    // MARK: - Mutations: conversation

    func addBuzzBack(buzzID: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        buzzBacks.append(BuzzBack(buzzID: buzzID, authorID: me.id, authorUsername: me.username, text: trimmed))
        if let index = buzzes.firstIndex(where: { $0.id == buzzID }) {
            buzzes[index].buzzBackCount += 1
        }
    }

    func addWitness(buzzID: String, angle: WitnessAngle, note: String) {
        witnessClaims.append(
            WitnessClaim(buzzID: buzzID, authorID: me.id, authorUsername: me.username, angle: angle, note: note)
        )
        if let index = buzzes.firstIndex(where: { $0.id == buzzID }) {
            buzzes[index].iWasThereCount += 1
        }
    }

    // MARK: - Mutations: posting

    /// Creates a local Buzz for this session, authored by the user's Fly.
    @discardableResult
    func postBuzz(text: String, category: BuzzCategory, tags: [String]) -> Buzz {
        let buzz = Buzz(
            id: "mine-\(UUID().uuidString.prefix(6))",
            authorID: me.id,
            authorUsername: me.username,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            tags: tags,
            postedAt: .now,
            area: "Your corner",
            isMine: true
        )
        buzzes.insert(buzz, at: 0)
        myBuzzIDs.insert(buzz.id, at: 0)
        updateMe { $0.buzzCount += 1 }
        return buzz
    }

    // MARK: - Mutations: connections

    /// Proposes a connection between two buzzes, scores it with the local
    /// analyzer, and forms a Swarm when 3+ buzzes end up meaningfully linked.
    @discardableResult
    func proposeConnection(sourceID: String, targetID: String, clues: [ConnectionClue]) -> FlyConnection? {
        guard sourceID != targetID,
              !clues.isEmpty,
              let source = buzz(id: sourceID),
              let target = buzz(id: targetID),
              connection(between: sourceID, and: targetID) == nil
        else { return nil }

        let result = ConnectionAnalyzer.analyze(source: source, target: target, selectedClues: clues)
        let link = FlyConnection(
            sourceID: sourceID,
            targetID: targetID,
            strength: result.strength,
            overlappingClues: result.overlappingClues,
            conflictingClues: result.conflictingClues,
            isUserProposed: true,
            createdAt: .now,
            swarmID: source.swarmID ?? target.swarmID
        )
        connections.append(link)
        formSwarmIfNeeded(from: sourceID)
        return link
    }

    // MARK: - Swarm formation

    /// Connected component of the link graph containing the seed buzz.
    private func linkedComponent(of buzzID: String) -> Set<String> {
        var component: Set<String> = [buzzID]
        var changed = true
        while changed {
            changed = false
            for link in connections {
                guard component.contains(link.sourceID) || component.contains(link.targetID) else { continue }
                if !component.contains(link.sourceID) {
                    component.insert(link.sourceID)
                    changed = true
                }
                if !component.contains(link.targetID) {
                    component.insert(link.targetID)
                    changed = true
                }
            }
        }
        return component
    }

    /// When 3+ linked buzzes carry at least two non-weak connections between
    /// them, the participating Flies group as a Swarm — reusing an existing
    /// one when possible.
    private func formSwarmIfNeeded(from buzzID: String) {
        let component = linkedComponent(of: buzzID)
        guard component.count >= 3 else { return }
        let meaningful = connections.filter {
            $0.strength != .weakBuzz && component.contains($0.sourceID) && component.contains($0.targetID)
        }
        guard meaningful.count >= 2 else { return }

        let members = component.compactMap { buzz(id: $0) }

        // Already circling a swarm: attach any unattached links to it and stop.
        if let existingSwarmID = members.compactMap(\.swarmID).first {
            connections = connections.map { link in
                guard link.swarmID == nil, component.contains(link.sourceID), component.contains(link.targetID) else { return link }
                return link.attached(to: existingSwarmID)
            }
            return
        }

        var authorIDs: [String] = []
        for buzz in members where !authorIDs.contains(buzz.authorID) {
            authorIDs.append(buzz.authorID)
        }

        let swarmID = "swarm-new-\(Int(Date.now.timeIntervalSinceReferenceDate) % 100_000)"
        let swarm = Swarm(
            id: swarmID,
            title: "THE \(authorIDs.count)-FLY SITUATION",
            teaser: "Enough overlapping details that these Flies started circling each other.",
            buzzIDs: members.map(\.id),
            authorIDs: authorIDs
        )
        swarms.append(swarm)
        buzzes = buzzes.map { stored in
            component.contains(stored.id) ? stored.joining(swarmID: swarmID) : stored
        }
        connections = connections.map { link in
            component.contains(link.sourceID) && component.contains(link.targetID)
                ? link.attached(to: swarmID) : link
        }
    }

    // MARK: - Helpers

    private func updateMe(_ transform: (inout FlyProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.isMe }) else { return }
        transform(&profiles[index])
    }
}
