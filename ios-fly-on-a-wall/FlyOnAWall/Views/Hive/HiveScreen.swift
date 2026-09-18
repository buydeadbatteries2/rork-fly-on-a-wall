//
//  HiveScreen.swift
//  FlyOnAWall
//
//  A Fly's Hive — their mini-blog inside Fly on a Wall. Used for other
//  bloggers and, with isMe tweaks, for the current user's own profile.
//  This is one of the few places scrolling content is acceptable.
//

import SwiftUI

struct HiveScreen: View {
    let flyID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @State private var filter: BuzzCategory?
    @State private var showShare: Bool = false

    private var fly: FlyProfile? { store.profile(id: flyID) }
    private var isMe: Bool { fly?.isMe ?? false }
    private var isFollowing: Bool { store.isFollowing(flyID) }

    private var allBuzzes: [Buzz] {
        guard let fly else { return [] }
        return store.buzzes(by: fly.id).sorted { $0.postedAt > $1.postedAt }
    }

    private var buzzes: [Buzz] {
        guard let filter else { return allBuzzes }
        return allBuzzes.filter { $0.category == filter }
    }

    /// Only categories this Fly actually has content in.
    private var availableCategories: [BuzzCategory] {
        var seen: [BuzzCategory] = []
        for buzz in allBuzzes where !seen.contains(buzz.category) {
            seen.append(buzz.category)
        }
        return seen
    }

    var body: some View {
        ZStack {
            WallBackdrop(tint: fly?.currentStatus.tint, tintStrength: 0.10)

            if let fly {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !isMe {
                            HStack {
                                BackChip { path.removeLast() }
                                Spacer()
                                Text("\(fly.buzzCount) BUZZES")
                                    .font(WallFont.stamp(12))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(WallTheme.ink.opacity(0.7)))
                            }
                        }

                        headerCard(fly)
                        statsRow(fly)

                        if !isMe {
                            actionButtons(fly)
                        }

                        filterChips

                        buzzList

                        if isMe {
                            followingSection
                        }

                        Color.clear.frame(height: WallMetrics.tabBarClearance)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, isMe ? 8 : 4)
                }
                .scrollIndicators(.hidden)
            } else {
                Text("This hive buzzed off.")
                    .font(WallFont.marker(16))
                    .foregroundStyle(WallTheme.inkSoft)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("HIVE LINK COPIED", isPresented: $showShare) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Well, it would be. Hives aren't wired to the outside world yet.")
        }
    }

    // MARK: - Header

    private func headerCard(_ fly: FlyProfile) -> some View {
        TapedPaper(rotation: -1.2, padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    FlyView(status: fly.currentStatus, size: 36, wingsBeating: true)
                        .frame(width: 58, height: 50)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isMe ? "MY HIVE" : fly.username)
                            .font(WallFont.stencil(isMe ? 30 : 26))
                            .foregroundStyle(WallTheme.ink)
                        if !isMe {
                            Text(fly.displayName)
                                .font(WallFont.stamp(11))
                                .foregroundStyle(WallTheme.rust)
                        }
                        Text("\"\(fly.tagline)\"")
                            .font(WallFont.marker(14, weight: .regular))
                            .foregroundStyle(WallTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                statusChip(fly)
            }
        }
    }

    private func statusChip(_ fly: FlyProfile) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(fly.currentStatus.tint)
                .frame(width: 8, height: 8)
            Text("\(fly.currentStatus.title) · \(fly.currentStatus.blurb)")
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    private func statsRow(_ fly: FlyProfile) -> some View {
        HStack(spacing: 8) {
            stat(fly.followerDisplay, "FOLLOWERS")
            stat("\(fly.buzzCount)", "BUZZES")
            stat(fly.scoreDisplay, "BUZZ SCORE")
        }
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(WallFont.stencil(22))
                .foregroundStyle(WallTheme.paper)
            Text(label)
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.paper.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.ink.opacity(0.62))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.14), lineWidth: 1))
        }
    }

    private func actionButtons(_ fly: FlyProfile) -> some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                store.toggleFollow(fly.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isFollowing ? "checkmark" : "ant.fill")
                        .font(.system(size: 15, weight: .heavy))
                    Text(isFollowing ? "FOLLOWING" : "FOLLOW FLY")
                        .font(WallFont.stencil(18))
                        .kerning(1.0)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    if isFollowing {
                        Capsule()
                            .fill(WallTheme.ink.opacity(0.85))
                            .overlay(Capsule().stroke(WallTheme.teal.opacity(0.9), lineWidth: 1.6))
                    } else {
                        RustPlateBackground(color: WallTheme.teal)
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(isFollowing ? "Following \(fly.username)" : "Follow \(fly.username)")

            Button {
                Haptics.tap()
                showShare = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .heavy))
                    Text("SHARE HIVE")
                        .font(WallFont.stencil(18))
                        .kerning(1.0)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background { RustPlateBackground(color: WallTheme.inkSoft) }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Share hive")
        }
    }

    // MARK: - Content

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip(title: "ALL", emoji: nil, category: nil)
                ForEach(availableCategories) { category in
                    chip(title: category.title, emoji: category.emoji, category: category)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, emoji: String?, category: BuzzCategory?) -> some View {
        let isActive = filter == category
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                filter = category
            }
        } label: {
            HStack(spacing: 4) {
                if let emoji {
                    Text(emoji).font(.system(size: 11))
                }
                Text(title)
                    .font(WallFont.stamp(10))
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isActive ? (category?.tint ?? WallTheme.ink) : WallTheme.paper.opacity(0.9))
                    .overlay(Capsule().stroke(WallTheme.inkSoft.opacity(isActive ? 0.8 : 0.45), lineWidth: 1.2))
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
    }

    @ViewBuilder
    private var buzzList: some View {
        if buzzes.isEmpty {
            TapedPaper(rotation: 0.8, padding: 14) {
                Text(isMe
                     ? "Nothing posted yet. The wall is waiting for it."
                     : "No buzz in this corner of the hive yet.")
                    .font(WallFont.marker(14, weight: .regular))
                    .foregroundStyle(WallTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(spacing: 4) {
                ForEach(buzzes) { buzz in
                    BuzzRow(buzz: buzz, showsAuthor: !isMe) {
                        Haptics.tap()
                        path.append(WallRoute.buzz(buzz.id))
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    /// Only on the user's own Hive: the Flies they follow.
    @ViewBuilder
    private var followingSection: some View {
        let following = store.followedFlies
        VStack(alignment: .leading, spacing: 10) {
            Text("FLIES YOU FOLLOW")
                .font(WallFont.stencil(22))
                .foregroundStyle(WallTheme.paper)
                .shadow(color: .black.opacity(0.55), radius: 4, y: 2)

            if following.isEmpty {
                TapedPaper(rotation: -0.8, padding: 14) {
                    Text("Follow a fly and their hive will keep buzzing here.")
                        .font(WallFont.marker(14, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(following) { followed in
                    FlyRow(fly: followed) {
                        Haptics.tap()
                        path.append(WallRoute.hive(followed.id))
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}
