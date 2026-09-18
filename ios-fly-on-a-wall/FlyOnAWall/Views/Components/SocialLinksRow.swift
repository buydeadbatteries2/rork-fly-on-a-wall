//
//  SocialLinksRow.swift
//  FlyOnAWall
//
//  Compact stamped chips for a Fly's configured social links. Only services
//  with a stored URL render; taps open the URL through the system.
//

import SwiftUI

struct SocialLinksRow: View {
    let links: FlySocialLinks
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 6) {
            ForEach(links.activeLinks) { link in
                Button {
                    Haptics.tap()
                    openURL(link.url)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: link.service.symbol)
                            .font(.system(size: 10, weight: .bold))
                        Text(link.service.shortLabel)
                            .font(WallFont.stamp(11))
                            .kerning(0.6)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(WallTheme.ink.opacity(0.82))
                            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                }
                .buttonStyle(PressableButtonStyle(scale: 0.92))
                .accessibilityLabel("\(link.service.accessibilityName) link for this fly")
            }
            Spacer(minLength: 0)
        }
    }
}
