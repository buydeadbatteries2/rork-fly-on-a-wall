//
//  WallRoute.swift
//  FlyOnAWall
//

import Foundation

/// Type-safe push destinations shared by every navigation stack.
enum WallRoute: Hashable {
    /// One Buzz, in full.
    case buzz(String)
    /// A Fly's Hive (public blog page; also used for "me").
    case hive(String)
    case swarm(String)
    /// Phase 2 investigation board for one buzz's connections.
    case connectionBoard(String)
}
