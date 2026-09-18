//
//  FlySocialLinks.swift
//  FlyOnAWall
//
//  Optional public social links on a Fly's Hive. Services are fixed; values
//  are URLs. Only configured services ever render — no empty icons.
//

import Foundation

/// The services a Fly can publish on their Hive.
enum SocialService: String, CaseIterable, Codable, Hashable {
    case instagram
    case tiktok
    case youtube
    case x
    case facebook
    case website

    /// Short stamped label used on Hive chips.
    var shortLabel: String {
        switch self {
        case .instagram: "IG"
        case .tiktok: "TT"
        case .youtube: "YT"
        case .x: "X"
        case .facebook: "FB"
        case .website: "WEB"
        }
    }

    /// SF Symbol shown beside the stamped label.
    var symbol: String {
        switch self {
        case .instagram: "camera.fill"
        case .tiktok: "music.note"
        case .youtube: "play.rectangle.fill"
        case .x: "at"
        case .facebook: "person.2.fill"
        case .website: "globe"
        }
    }

    var accessibilityName: String {
        switch self {
        case .instagram: "Instagram"
        case .tiktok: "TikTok"
        case .youtube: "YouTube"
        case .x: "X"
        case .facebook: "Facebook"
        case .website: "Website"
        }
    }
}

/// One configured social link, ready to open natively.
struct SocialLink: Identifiable, Hashable {
    let service: SocialService
    let url: URL
    var id: String { service.rawValue }
}

/// A Fly's public social links. Unset services are nil and never rendered.
struct FlySocialLinks: Codable, Hashable {
    var instagram: String?
    var tiktok: String?
    var youtube: String?
    var x: String?
    var facebook: String?
    var website: String?

    init(
        instagram: String? = nil,
        tiktok: String? = nil,
        youtube: String? = nil,
        x: String? = nil,
        facebook: String? = nil,
        website: String? = nil
    ) {
        self.instagram = instagram
        self.tiktok = tiktok
        self.youtube = youtube
        self.x = x
        self.facebook = facebook
        self.website = website
    }

    var isEmpty: Bool { activeLinks.isEmpty }

    /// Configured links in display order, normalized to https URLs.
    var activeLinks: [SocialLink] {
        var links: [SocialLink] = []
        func add(_ service: SocialService, _ raw: String?) {
            guard let raw else { return }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            let urlString = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
                ? trimmed
                : "https://\(trimmed)"
            guard let url = URL(string: urlString) else { return }
            links.append(SocialLink(service: service, url: url))
        }
        add(.instagram, instagram)
        add(.tiktok, tiktok)
        add(.youtube, youtube)
        add(.x, x)
        add(.facebook, facebook)
        add(.website, website)
        return links
    }
}
