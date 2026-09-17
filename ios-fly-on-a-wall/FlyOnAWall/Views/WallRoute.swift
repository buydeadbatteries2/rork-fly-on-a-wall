//
//  WallRoute.swift
//  FlyOnAWall
//

import Foundation

/// Type-safe push destinations shared by every navigation stack.
enum WallRoute: Hashable {
    case category(FlyCategory)
    case story(String)
    case swarm(String)
}
