//
//  FlyProfile.swift
//  FlyOnAWall
//
//  A Fly is a USER / BLOGGER / CREATOR. Every Fly owns a Hive (their blog),
//  publishes Buzzes, and has a Buzz Score. Clean enough to back with real
//  accounts later without changing the UI layer.
//

import Foundation

struct FlyProfile: Identifiable, Hashable, Codable {
    let id: String
    /// Public handle, e.g. "@MessyJessy".
    let username: String
    /// Optional display name, e.g. "Jessy".
    let displayName: String
    /// One-line bio shown at the top of the Hive.
    let tagline: String
    /// Reputation / engagement score. Mock only.
    var buzzScore: Int
    var followerCount: Int
    var followingCount: Int
    /// Total published Buzzes, including ones not stored locally.
    var buzzCount: Int
    /// What this Fly tends to post about.
    let interests: [BuzzCategory]
    /// What is currently happening around this Fly's Buzz. Not an identity —
    /// colours change as the Fly's Buzz changes.
    var currentStatus: FlyStatus
    /// Optional public social links shown on the Hive. Nil/empty = no icons.
    var socialLinks: FlySocialLinks?
    /// The Buzz previewed when this Fly is tapped on The Wall.
    let featuredBuzzID: String?
    let joinedAt: Date
    /// True for the local, session-only profile of the person holding the phone.
    let isMe: Bool

    init(
        id: String,
        username: String,
        displayName: String,
        tagline: String,
        buzzScore: Int = 0,
        followerCount: Int = 0,
        followingCount: Int = 0,
        buzzCount: Int = 0,
        interests: [BuzzCategory] = [],
        currentStatus: FlyStatus = .new,
        socialLinks: FlySocialLinks? = nil,
        featuredBuzzID: String? = nil,
        joinedAt: Date = .now,
        isMe: Bool = false
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.tagline = tagline
        self.buzzScore = buzzScore
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.buzzCount = buzzCount
        self.interests = interests
        self.currentStatus = currentStatus
        self.socialLinks = socialLinks
        self.featuredBuzzID = featuredBuzzID
        self.joinedAt = joinedAt
        self.isMe = isMe
    }

    /// "14.8K" style follower count.
    var followerDisplay: String {
        followerCount >= 1000
            ? String(format: "%.1fK", Double(followerCount) / 1000.0)
            : "\(followerCount)"
    }

    /// Buzz Score in short form, e.g. "18.4K".
    var scoreDisplay: String {
        buzzScore >= 1000
            ? String(format: "%.1fK", Double(buzzScore) / 1000.0)
            : "\(buzzScore)"
    }

    /// "2 days ago" style stamp for Hive headers.
    var joinedAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: joinedAt, relativeTo: .now)
    }
}
