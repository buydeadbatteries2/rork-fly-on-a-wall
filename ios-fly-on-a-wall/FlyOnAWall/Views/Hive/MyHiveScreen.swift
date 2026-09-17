//
//  MyHiveScreen.swift
//  FlyOnAWall
//
//  Themed placeholder: your flies, followed flies, buzzes.
//

import SwiftUI

struct MyHiveScreen: View {
    @Binding var path: [WallRoute]
    @Environment(WallStore.self) private var store

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.warmGray, tintStrength: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "MY HIVE", size: 42)
                        Text("Anonymous. Even to us.")
                            .font(WallFont.marker(15))
                            .foregroundStyle(WallTheme.ink.opacity(0.85))
                            .shadow(color: WallTheme.bone.opacity(0.5), radius: 0, x: 1, y: 1)
                    }
                    .padding(.top, 8)

                    HStack(spacing: 10) {
                        tally("\(store.myFlies.count)", "MY FLIES")
                        tally("\(store.followedFlies.count)", "FOLLOWED")
                        tally("\(store.totalBuzzes)", "BUZZES")
                    }

                    flyList(title: "MY FLIES", empty: "Nothing confessed yet. The wall is waiting.", flies: store.myFlies)
                    flyList(title: "FOLLOWING", empty: "Follow a fly and it will keep buzzing here.", flies: store.followedFlies)

                    TapedPaper(rotation: -1.0, padding: 16) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("NO NAMES. NO PROFILE.")
                                .font(WallFont.stencil(17))
                                .foregroundStyle(WallTheme.rust)
                            Text("Your hive lives on this phone for now. Nothing here has your name on it.")
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

    private func tally(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(WallFont.stencil(28))
                .foregroundStyle(WallTheme.paper)
            Text(label)
                .font(WallFont.stamp(10))
                .foregroundStyle(WallTheme.paper.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.ink.opacity(0.62))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.14), lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
    }

    private func flyList(title: String, empty: String, flies: [StoryFly]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(WallFont.stencil(22))
                .foregroundStyle(WallTheme.paper)
                .shadow(color: .black.opacity(0.55), radius: 4, y: 2)

            if flies.isEmpty {
                TapedPaper(rotation: 0.8, padding: 14) {
                    Text(empty)
                        .font(WallFont.marker(14, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
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
                                    Text(fly.handle)
                                        .font(WallFont.stamp(11))
                                        .foregroundStyle(WallTheme.rust)
                                    Text(fly.text)
                                        .font(WallFont.marker(14, weight: .regular))
                                        .foregroundStyle(WallTheme.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
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
}
