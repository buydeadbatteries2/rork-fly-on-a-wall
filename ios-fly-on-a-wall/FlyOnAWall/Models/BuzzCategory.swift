//
//  BuzzCategory.swift
//  FlyOnAWall
//
//  Content categories. Categories belong to BUZZES, never to Flies — one Fly
//  can post across any mix of these.
//

import SwiftUI

/// What a Buzz is about. Used by the Wall filter, Hive filters and Explore.
enum BuzzCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case hotBuzz
    case celebrity
    case relationships
    case workplace
    case music
    case sports
    case internet
    case embarrassing
    case wtf
    case localBuzz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hotBuzz: "HOT BUZZ"
        case .celebrity: "CELEBRITY"
        case .relationships: "RELATIONSHIPS"
        case .workplace: "WORKPLACE"
        case .music: "MUSIC"
        case .sports: "SPORTS"
        case .internet: "INTERNET"
        case .embarrassing: "EMBARRASSING"
        case .wtf: "WTF?!"
        case .localBuzz: "LOCAL BUZZ"
        }
    }

    var emoji: String {
        switch self {
        case .hotBuzz: "🔥"
        case .celebrity: "🎤"
        case .relationships: "❤️"
        case .workplace: "💼"
        case .music: "🎵"
        case .sports: "🏀"
        case .internet: "📱"
        case .embarrassing: "😂"
        case .wtf: "🤯"
        case .localBuzz: "📍"
        }
    }

    var tint: Color {
        switch self {
        case .hotBuzz: Color(red: 0.66, green: 0.20, blue: 0.14)
        case .celebrity: Color(red: 0.80, green: 0.66, blue: 0.24)
        case .relationships: Color(red: 0.76, green: 0.36, blue: 0.42)
        case .workplace: Color(red: 0.36, green: 0.40, blue: 0.47)
        case .music: Color(red: 0.16, green: 0.45, blue: 0.50)
        case .sports: Color(red: 0.42, green: 0.48, blue: 0.25)
        case .internet: Color(red: 0.28, green: 0.50, blue: 0.66)
        case .embarrassing: Color(red: 0.85, green: 0.52, blue: 0.40)
        case .wtf: Color(red: 0.55, green: 0.62, blue: 0.22)
        case .localBuzz: Color(red: 0.247, green: 0.490, blue: 0.455)
        }
    }

    /// One-line meaning, shown under section headers and on The Wall chips.
    var blurb: String {
        switch self {
        case .hotBuzz: "The whole wall is talking about this."
        case .celebrity: "Someone famous did something. Allegedly."
        case .relationships: "Hearts, red flags, and group chat receipts."
        case .workplace: "HR has been notified. Repeatedly."
        case .music: "Live shows, bad karaoke, worse lyrics."
        case .sports: "Scores, spats, and stadium drama."
        case .internet: "Terminally online. Proud of it."
        case .embarrassing: "Cringe, but with witnesses."
        case .wtf: "No further explanation provided."
        case .localBuzz: "Buzzing around your corner of the world."
        }
    }

    /// Tag suggestions for the composer and the mock tag generator.
    var suggestedTags: [String] {
        switch self {
        case .hotBuzz: ["#Trending", "#EverybodyKnows", "#NoNotes"]
        case .celebrity: ["#Spotted", "#Tea", "#Allegedly"]
        case .relationships: ["#RedFlags", "#Situationship", "#Receipts"]
        case .workplace: ["#HR", "#Meeting", "#QuitYourJob"]
        case .music: ["#Encore", "#LiveMusic", "#OffKey"]
        case .sports: ["#GameDay", "#Section12", "#Overtime"]
        case .internet: ["#ChronicallyOnline", "#Screenshot", "#GroupChat"]
        case .embarrassing: ["#WhyDidIDoThat", "#NoRegrets", "#Cringe"]
        case .wtf: ["#Unhinged", "#ExplainThis", "#NoContext"]
        case .localBuzz: ["#Spotted", "#OnlyHere", "#CornerStore"]
        }
    }
}
