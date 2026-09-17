//
//  ExploreScreen.swift
//  FlyOnAWall
//
//  Themed placeholder: Hot Buzz and Buzzing Around You.
//

import SwiftUI

struct ExploreScreen: View {
    @Binding var path: [WallRoute]
    @Environment(WallStore.self) private var store

    private var hotBuzz: [StoryFly] {
        store.stories(in: .hot).sorted { $0.reactionCount > $1.reactionCount }.prefix(3).map { $0 }
    }

    private var nearby: [StoryFly] {
        store.stories(in: .local).prefix(3).map { $0 }
    }

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.rust, tintStrength: 0.10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "EXPLORE", size: 42)
                        Text("Where the wall is loudest right now.")
                            .font(WallFont.marker(15))
                            .foregroundStyle(WallTheme.ink.opacity(0.85))
                            .shadow(color: WallTheme.bone.opacity(0.5), radius: 0, x: 1, y: 1)
                    }
                    .padding(.top, 8)

                    section(title: "HOT BUZZ", category: .hot, flies: hotBuzz)
                    section(title: "BUZZING AROUND YOU", category: .local, flies: nearby)

                    TapedPaper(rotation: 1.2, padding: 16) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MORE COMING")
                                .font(WallFont.stencil(17))
                                .foregroundStyle(WallTheme.rust)
                            Text("Searching the wall, saved swarms, and buzzing corners are still being scraped off the bricks.")
                                .font(WallFont.marker(14, weight: .regular))
                                .foregroundStyle(WallTheme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Color.clear.frame(height: WallMetrics.tabBarClearance)
                }
                .padding(.horizontal, 18)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func section(title: String, category: FlyCategory, flies: [StoryFly]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                FlyView(category: category, size: 22, wingsBeating: false)
                    .frame(width: 38, height: 32)
                Text(title)
                    .font(WallFont.stencil(22))
                    .foregroundStyle(WallTheme.paper)
                    .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
                Spacer()
                Button {
                    Haptics.tap()
                    path.append(WallRoute.category(category))
                } label: {
                    Text("SEE ALL")
                        .font(WallFont.stamp(11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(WallTheme.ink.opacity(0.7)))
                }
                .buttonStyle(PressableButtonStyle())
            }

            ForEach(flies) { fly in
                Button {
                    Haptics.tap()
                    path.append(WallRoute.story(fly.id))
                } label: {
                    TapedPaper(rotation: Double(abs(fly.id.hashValue % 3)) - 1.0, padding: 14) {
                        HStack(spacing: 12) {
                            FlyView(category: fly.category, size: 24, wingsBeating: false)
                                .frame(width: 42, height: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(fly.text)
                                    .font(WallFont.marker(14, weight: .regular))
                                    .foregroundStyle(WallTheme.ink)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("😂 \(fly.reactionCount)  ·  👀 \(fly.witnessCount)")
                                    .font(WallFont.stamp(11))
                                    .foregroundStyle(WallTheme.inkSoft)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle(scale: 0.98))
            }
        }
    }
}
