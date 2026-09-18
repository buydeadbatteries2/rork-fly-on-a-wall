//
//  ExploreScreen.swift
//  FlyOnAWall
//
//  EXPLORE THE BUZZ — what's buzzing, browse categories, flies to follow,
//  active swarms, fresh flies, local buzz. All mock, all local.
//

import SwiftUI

struct ExploreScreen: View {
    @Binding var path: [WallRoute]
    @Environment(WallStore.self) private var store
    @State private var browseCategory: BuzzCategory?

    private var whatsBuzzing: [Buzz] {
        store.buzzes.sorted { $0.reactionCount > $1.reactionCount }.prefix(4).map { $0 }
    }

    private var suggestedFlies: [FlyProfile] {
        store.profiles
            .filter { !$0.isMe && !store.isFollowing($0.id) }
            .sorted { $0.followerCount > $1.followerCount }
            .prefix(4)
            .map { $0 }
    }

    private var freshFlies: [FlyProfile] {
        store.profiles
            .filter { !$0.isMe }
            .sorted { $0.joinedAt > $1.joinedAt }
            .prefix(3)
            .map { $0 }
    }

    private var localBuzzes: [Buzz] {
        store.buzzes.filter { $0.area != nil }.prefix(3).map { $0 }
    }

    private var browseBuzzes: [Buzz] {
        guard let browseCategory else { return [] }
        return store.buzzes(in: browseCategory).sorted { $0.reactionCount > $1.reactionCount }.prefix(3).map { $0 }
    }

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.rust, tintStrength: 0.10)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "EXPLORE THE BUZZ", size: 36)
                        Text("Where the wall is loudest right now.")
                            .font(WallFont.meta(13))
                            .foregroundStyle(WallTheme.ink)
                            .shadow(color: WallTheme.bone.opacity(0.6), radius: 0, x: 1, y: 1)
                    }
                    .padding(.top, 8)

                    buzzSection(emoji: "🔥", title: "WHAT'S BUZZING", buzzes: whatsBuzzing)

                    browseSection

                    flySection(emoji: "🪰", title: "FLIES TO FOLLOW", flies: suggestedFlies)

                    swarmsSection

                    flySection(emoji: "🆕", title: "FRESH FLIES", flies: freshFlies)

                    buzzSection(emoji: "📍", title: "LOCAL BUZZ", buzzes: localBuzzes)

                    Color.clear.frame(height: WallMetrics.tabBarClearance)
                }
                .padding(.horizontal, 18)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Sections

    /// Section headers sit on a painted wall patch so they never fight the texture.
    private func sectionHeader(_ emoji: String, _ title: String) -> some View {
        WallPatch(title: "\(emoji) \(title)", titleSize: 20)
    }

    @ViewBuilder
    private func buzzSection(emoji: String, title: String, buzzes: [Buzz]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(emoji, title)
            // Wide wall-like gaps: each preview reads as its own pasted scrap.
            VStack(spacing: 18) {
                ForEach(buzzes) { buzz in
                    BuzzRow(buzz: buzz) {
                        Haptics.tap()
                        path.append(WallRoute.buzz(buzz.id))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func flySection(emoji: String, title: String, flies: [FlyProfile]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(emoji, title)
            ForEach(flies) { fly in
                FlyRow(fly: fly) {
                    Haptics.tap()
                    path.append(WallRoute.hive(fly.id))
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("🏷️", "BROWSE CATEGORIES")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(BuzzCategory.allCases) { category in
                    browseChip(category)
                }
            }

            if let browseCategory {
                if browseBuzzes.isEmpty {
                    TapedPaper(rotation: 0.8, padding: 14) {
                        Text("Nothing buzzing in \(browseCategory.title) yet.")
                            .font(WallFont.marker(14, weight: .regular))
                            .foregroundStyle(WallTheme.ink)
                    }
                } else {
                    VStack(spacing: 18) {
                        ForEach(browseBuzzes) { buzz in
                            BuzzRow(buzz: buzz) {
                                Haptics.tap()
                                path.append(WallRoute.buzz(buzz.id))
                            }
                        }
                    }
                }
            }
        }
    }

    private func browseChip(_ category: BuzzCategory) -> some View {
        let isActive = browseCategory == category
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                browseCategory = isActive ? nil : category
            }
        } label: {
            HStack(spacing: 5) {
                Text(category.emoji).font(.system(size: 13))
                Text(category.title)
                    .font(WallFont.stamp(11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isActive ? category.tint : WallTheme.paper.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isActive ? WallTheme.ink.opacity(0.6) : WallTheme.inkSoft.opacity(0.5), lineWidth: isActive ? 1.6 : 1.2)
                    )
            )
            .wallShadow(radius: 4, y: 2)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
        .accessibilityLabel("Browse \(category.title)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var swarmsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("🪰🪰", "ACTIVE SWARMS")

            ForEach(store.swarms) { swarm in
                Button {
                    Haptics.tap()
                    path.append(WallRoute.swarm(swarm.id))
                } label: {
                    TapedPaper(rotation: Double(abs(swarm.id.hashValue % 3)) - 1.0, padding: 14) {
                        HStack(spacing: 11) {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(FlyStatus.connected.tint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(swarm.title)
                                    .font(WallFont.stencil(17))
                                    .foregroundStyle(WallTheme.ink)
                                Text("\(store.flyCount(for: swarm)) FLIES · \(swarm.buzzCount) BUZZES · \(swarm.teaser)")
                                    .font(WallFont.meta(12, weight: .medium))
                                    .foregroundStyle(WallTheme.inkSoft)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(WallTheme.inkSoft.opacity(0.6))
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle(scale: 0.98))
            }
        }
    }
}
