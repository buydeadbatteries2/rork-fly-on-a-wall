//
//  FlyRow.swift
//  FlyOnAWall
//
//  One blogger Fly as a taped scrap — used by Explore and the Following list.
//

import SwiftUI

struct FlyRow: View {
    let fly: FlyProfile
    let action: () -> Void

    @Environment(WallStore.self) private var store

    private var rotation: Double {
        Double(abs(fly.id.hashValue % 3)) - 1.0
    }

    var body: some View {
        Button(action: action) {
            TapedPaper(rotation: rotation, padding: 14) {
                HStack(spacing: 12) {
                    FlyView(status: fly.currentStatus, size: 26, wingsBeating: false)
                        .frame(width: 46, height: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(fly.username)
                            .font(WallFont.stencil(16))
                            .foregroundStyle(WallTheme.ink)
                        Text("\"\(fly.tagline)\"")
                            .font(WallFont.marker(12, weight: .regular))
                            .foregroundStyle(WallTheme.inkSoft)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(fly.currentStatus.title)
                                .font(WallFont.stamp(8))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(fly.currentStatus.tint.opacity(0.9)))
                            Text("\(fly.followerDisplay) FOLLOWERS")
                                .font(WallFont.stamp(9))
                                .foregroundStyle(WallTheme.inkSoft)
                            if store.isFollowing(fly.id) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(WallTheme.teal)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(WallTheme.inkSoft.opacity(0.6))
                }
            }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityLabel("\(fly.username). \(fly.tagline). \(fly.followerDisplay) followers. \(fly.currentStatus.blurb)")
    }
}
