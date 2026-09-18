//
//  BuzzRow.swift
//  FlyOnAWall
//
//  One Buzz as a taped scrap — used in Hives and Explore. Scrolling content
//  lives only inside Hives/reading, never on The Wall itself.
//

import SwiftUI

struct BuzzRow: View {
    let buzz: Buzz
    /// Show the author handle (off inside the author's own Hive).
    var showsAuthor: Bool = true
    let action: () -> Void

    @Environment(WallStore.self) private var store

    private var rotation: Double {
        Double(abs(buzz.id.hashValue % 3)) - 1.0
    }

    var body: some View {
        Button(action: action) {
            TapedPaper(rotation: rotation, padding: 14) {
                HStack(spacing: 12) {
                    if let author = store.profile(id: buzz.authorID) {
                        FlyView(status: author.currentStatus, size: 24, wingsBeating: false)
                            .frame(width: 42, height: 36)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(buzz.category.emoji)
                                .font(.system(size: 11))
                            Text(buzz.category.title)
                                .font(WallFont.stamp(9))
                                .foregroundStyle(WallTheme.inkSoft)
                            if showsAuthor {
                                Text(buzz.authorUsername)
                                    .font(WallFont.stamp(9))
                                    .foregroundStyle(WallTheme.rust)
                            }
                        }
                        Text(buzz.text)
                            .font(WallFont.marker(14, weight: .regular))
                            .foregroundStyle(WallTheme.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("😂 \(buzz.reactionCount)  ·  💬 \(buzz.buzzBackCount)  ·  👀 \(buzz.iWasThereCount)")
                            .font(WallFont.stamp(10))
                            .foregroundStyle(WallTheme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityLabel("\(buzz.category.title) from \(buzz.authorUsername). \(buzz.text)")
    }
}
