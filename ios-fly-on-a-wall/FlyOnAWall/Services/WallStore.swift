//
//  WallStore.swift
//  FlyOnAWall
//
//  Session-local state. Everything here is in-memory mock data for Phase 1;
//  a real service can replace the bodies without changing any view.
//

import Foundation
import SwiftUI

@Observable
final class WallStore {
    private(set) var stories: [StoryFly]
    private(set) var swarms: [Swarm]
    private(set) var witnessClaims: [WitnessClaim] = []
    /// Flies posted during this session, newest first.
    private(set) var myFlyIDs: [String] = []
    /// Story IDs the user reacted to with 😂.
    private(set) var reactedIDs: Set<String> = []
    /// Story-to-story links. Stories only — never identification of people.
    private(set) var connections: [FlyConnection] = MockWallData.connections

    init(stories: [StoryFly] = MockWallData.stories, swarms: [Swarm] = MockWallData.swarms) {
        self.stories = stories
        self.swarms = swarms
    }

    // MARK: - Reads

    func stories(in category: FlyCategory) -> [StoryFly] {
        stories.filter { $0.category == category }
    }

    func story(id: String) -> StoryFly? {
        stories.first { $0.id == id }
    }

    func stories(in swarm: Swarm) -> [StoryFly] {
        swarm.storyIDs.compactMap { id in stories.first { $0.id == id } }
    }

    /// Other flies that plausibly touch this one: the connection graph first,
    /// then the Phase 1 connection-strength heuristic for unlinked flies.
    func connectedFlies(to story: StoryFly) -> [StoryFly] {
        let linked = connections(touching: story.id)
            .compactMap { self.story(id: $0.other(end: story.id)) }
        if !linked.isEmpty { return linked }

        var result: [StoryFly] = []
        if let swarmID = story.swarmID {
            result += stories.filter { $0.swarmID == swarmID && $0.id != story.id }
        }
        if result.count < 3 {
            let extras = stories
                .filter { $0.id != story.id && !result.contains($0) && $0.connectionStrength > 0.4 }
                .sorted { abs($0.connectionStrength - story.connectionStrength) < abs($1.connectionStrength - story.connectionStrength) }
                .prefix(3 - result.count)
            result += extras
        }
        return result
    }

    func count(for category: FlyCategory) -> Int {
        stories(in: category).count
    }

    var followedFlies: [StoryFly] {
        stories.filter(\.isFollowed)
    }

    var myFlies: [StoryFly] {
        myFlyIDs.compactMap { id in stories.first { $0.id == id } }
    }

    func claims(for storyID: String) -> [WitnessClaim] {
        witnessClaims.filter { $0.storyID == storyID }
    }

    var totalBuzzes: Int {
        witnessClaims.count + reactedIDs.count + followedFlies.count
    }

    // MARK: - Connections

    /// Every link touching a story, in either direction.
    func connections(touching storyID: String) -> [FlyConnection] {
        connections.filter { $0.involves(storyID) }
    }

    /// The link between two stories, if one exists.
    func connection(between storyA: String, and storyB: String) -> FlyConnection? {
        connections.first { $0.bothIDs.contains(storyA) && $0.bothIDs.contains(storyB) }
    }

    func swarm(for story: StoryFly) -> Swarm? {
        guard let swarmID = story.swarmID else { return nil }
        return swarms.first { $0.id == swarmID }
    }

    /// Strong / possible / weak counts for a swarm's internal connections.
    func connectionStats(for swarm: Swarm) -> (strong: Int, possible: Int, weak: Int) {
        let members = Set(swarm.storyIDs)
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

    // MARK: - Mutations

    func hasReacted(to storyID: String) -> Bool {
        reactedIDs.contains(storyID)
    }

    func toggleReaction(_ storyID: String) {
        guard let index = stories.firstIndex(where: { $0.id == storyID }) else { return }
        if reactedIDs.contains(storyID) {
            reactedIDs.remove(storyID)
            stories[index].reactionCount = max(0, stories[index].reactionCount - 1)
        } else {
            reactedIDs.insert(storyID)
            stories[index].reactionCount += 1
        }
    }

    func toggleFollow(_ storyID: String) {
        guard let index = stories.firstIndex(where: { $0.id == storyID }) else { return }
        stories[index].isFollowed.toggle()
    }

    func addWitness(storyID: String, angle: WitnessAngle, note: String) {
        guard let index = stories.firstIndex(where: { $0.id == storyID }) else { return }
        witnessClaims.append(WitnessClaim(storyID: storyID, angle: angle, note: note))
        stories[index].witnessCount += 1
    }

    /// Creates a temporary local fly for this session and returns it.
    @discardableResult
    func postFly(text: String) -> StoryFly {
        let number = Int.random(in: 3000...9999)
        let fly = StoryFly(
            id: "mine-\(UUID().uuidString.prefix(6))",
            handle: "Fly #\(number)",
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            category: .new,
            postedAt: .now,
            reactionCount: 0,
            witnessCount: 0,
            connectedFlyCount: 0,
            area: "Your corner",
            isMine: true
        )
        stories.insert(fly, at: 0)
        myFlyIDs.insert(fly.id, at: 0)
        return fly
    }

    /// Proposes a connection between two stories, scores it with the local
    /// analyzer, and forms a Swarm when 3+ flies end up meaningfully linked.
    @discardableResult
    func proposeConnection(sourceID: String, targetID: String, clues: [ConnectionClue]) -> FlyConnection? {
        guard sourceID != targetID,
              !clues.isEmpty,
              let source = story(id: sourceID),
              let target = story(id: targetID),
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

    /// Connected component of the link graph containing the seed story.
    private func linkedComponent(of storyID: String) -> Set<String> {
        var component: Set<String> = [storyID]
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

    /// When 3+ linked stories carry at least two non-weak connections between
    /// them, they group as a Swarm — reusing an existing one when possible.
    private func formSwarmIfNeeded(from storyID: String) {
        let component = linkedComponent(of: storyID)
        guard component.count >= 3 else { return }
        let meaningful = connections.filter {
            $0.strength != .weakBuzz && component.contains($0.sourceID) && component.contains($0.targetID)
        }
        guard meaningful.count >= 2 else { return }

        let flies = component.compactMap { story(id: $0) }

        // Already circling a swarm: attach any unattached links to it and stop.
        if let existingSwarmID = flies.compactMap(\.swarmID).first {
            connections = connections.map { link in
                guard link.swarmID == nil, component.contains(link.sourceID), component.contains(link.targetID) else { return link }
                return link.attached(to: existingSwarmID)
            }
            return
        }

        let swarmID = "swarm-new-\(Int(Date.now.timeIntervalSinceReferenceDate) % 100_000)"
        let swarm = Swarm(
            id: swarmID,
            title: "THE \(component.count)-FLY SITUATION",
            teaser: "Enough overlapping details that these flies started circling each other.",
            storyIDs: flies.map(\.id),
            categories: flies.map(\.category)
        )
        swarms.append(swarm)
        stories = stories.map { stored in
            component.contains(stored.id) ? stored.joining(swarmID: swarmID) : stored
        }
        connections = connections.map { link in
            component.contains(link.sourceID) && component.contains(link.targetID)
                ? link.attached(to: swarmID) : link
        }
    }
}
