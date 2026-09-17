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

    /// Other flies that plausibly touch this one: same swarm first, then the
    /// closest connection-strength matches.
    func connectedFlies(to story: StoryFly) -> [StoryFly] {
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
}
