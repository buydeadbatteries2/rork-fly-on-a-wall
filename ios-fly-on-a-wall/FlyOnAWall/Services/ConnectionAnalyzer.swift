//
//  ConnectionAnalyzer.swift
//  FlyOnAWall
//
//  Deterministic local mock analyzer: overlaps story metadata with the clues
//  the user selected. Scores similarity between STORY details and timestamps
//  only — it never identifies people. A real service can replace this one
//  function without touching any view.
//

import Foundation

enum ConnectionAnalyzer {
    struct Result: Hashable {
        let strength: ConnectionStrength
        let overlappingClues: [ConnectionClue]
        let conflictingClues: [String]
    }

    /// Thresholds on the internal similarity score.
    private static let strongThreshold: Double = 5.0
    private static let possibleThreshold: Double = 2.8

    static func analyze(
        source: StoryFly,
        target: StoryFly,
        selectedClues: [ConnectionClue]
    ) -> Result {
        var score: Double = 0

        // --- Story metadata agreement (independent signal, not user opinion) ---
        // Flies already circling the same swarm overlap by definition.
        if let swarmID = source.swarmID, swarmID == target.swarmID { score += 2 }

        let hours = abs(source.postedAt.timeIntervalSince(target.postedAt)) / 3600
        if hours < 12 {
            score += 1
        } else if hours < 30 {
            score += 0.5
        }

        if let areaA = source.area, let areaB = target.area {
            score += areaA == areaB ? 1 : -0.5
        }

        // Connection-flavoured categories carry built-in corroboration.
        let linky: (StoryFly) -> Bool = { $0.category == .connected || $0.category == .strongConnection }
        if linky(source), linky(target) {
            score += 1
        } else if linky(source) || linky(target) {
            score += 0.5
        }

        // --- Clue weights, most specific first so lists read well ---
        let clues = selectedClues.sorted { $0.weight > $1.weight }
        score += clues.reduce(0) { $0 + $1.weight }

        // --- Conflicts: deterministic, derived from the stories themselves ---
        var conflicts: [String] = []
        if hours > 60 { conflicts.append("The timelines don't line up") }
        if let areaA = source.area, let areaB = target.area, areaA != areaB {
            conflicts.append("Different areas reported")
        }
        if source.category == .inQuestion || target.category == .inQuestion,
           clues.contains(.detailsOverlap) {
            conflicts.append("One detail conflicts")
        }
        score -= Double(conflicts.count) * 0.8

        let strength: ConnectionStrength = score >= strongThreshold
            ? .strongBuzz
            : score >= possibleThreshold ? .possible : .weakBuzz

        return Result(strength: strength, overlappingClues: clues, conflictingClues: conflicts)
    }
}
