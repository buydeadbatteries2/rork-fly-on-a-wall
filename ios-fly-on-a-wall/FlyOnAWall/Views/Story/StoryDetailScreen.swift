//
//  StoryDetailScreen.swift
//  FlyOnAWall
//
//  Following a fly somewhere private to overhear the gossip.
//

import SwiftUI

struct StoryDetailScreen: View {
    let storyID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWitnessSheet: Bool = false
    @State private var showConnections: Bool = false
    @State private var showReport: Bool = false
    @State private var reactionKick: Bool = false
    @State private var followKick: Bool = false

    private var story: StoryFly? { store.story(id: storyID) }

    var body: some View {
        ZStack {
            WallBackdrop(tint: story?.category.tint, tintStrength: 0.12)

            if let story {
                content(story)
            } else {
                Text("This fly buzzed off.")
                    .font(WallFont.marker(16))
                    .foregroundStyle(WallTheme.inkSoft)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showWitnessSheet) {
            if let story {
                IWasThereSheet(story: story)
            }
        }
        .sheet(isPresented: $showConnections) {
            if let story {
                ConnectedFliesSheet(story: story, path: $path)
            }
        }
        .alert("Reported", isPresented: $showReport) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thanks. A fly will look into it.")
        }
    }

    private func content(_ story: StoryFly) -> some View {
        VStack(spacing: 0) {
            HStack {
                BackChip { path.removeLast() }
                Spacer()
                Text(story.category.title)
                    .font(WallFont.stamp(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(story.category.tint.opacity(story.category == .strongConnection ? 0.6 : 0.9)))
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)

            ScrollView {
                VStack(spacing: 18) {
                    identityCard(story)
                    confessionCard(story)
                    statsRow(story)
                    actionGrid(story)
                    if !store.claims(for: story.id).isEmpty {
                        witnessNotes(story)
                    }
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                PlateButton(title: "I WAS THERE", systemImage: "eye.fill", tint: WallTheme.rust) {
                    Haptics.thud()
                    showWitnessSheet = true
                }
                Text("\(story.witnessCount) flies say they saw it too")
                    .font(WallFont.stamp(10))
                    .foregroundStyle(WallTheme.paper.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.top, 6)
            .background {
                LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Cards

    private func identityCard(_ story: StoryFly) -> some View {
        TapedPaper(rotation: -1.6, padding: 14) {
            HStack(spacing: 12) {
                FlyView(category: story.category, size: 30, wingsBeating: false)
                    .frame(width: 48, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(story.handle) · Anonymous")
                        .font(WallFont.stencil(18))
                        .foregroundStyle(WallTheme.ink)
                    Text("Posted \(story.postedAgo)")
                        .font(WallFont.marker(12, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func confessionCard(_ story: StoryFly) -> some View {
        TapedPaper(rotation: 0.8, padding: 22) {
            Text(story.text)
                .font(WallFont.marker(21, weight: .medium))
                .foregroundStyle(WallTheme.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statsRow(_ story: StoryFly) -> some View {
        HStack(spacing: 8) {
            stat("\(story.reactionCount)", "laughs")
            stat("\(story.witnessCount)", "witnesses")
            stat("\(max(story.connectedFlyCount, store.connectedFlies(to: story).count))", "connected")
            if let area = story.area {
                stat(area.uppercased(), "area")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(WallFont.stencil(17))
                .foregroundStyle(WallTheme.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.paper.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(WallTheme.ink.opacity(0.62))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.14), lineWidth: 1))
        }
    }

    private func actionGrid(_ story: StoryFly) -> some View {
        HStack(spacing: 10) {
            actionTile(
                emoji: "😂",
                label: "\(story.reactionCount)",
                isActive: store.hasReacted(to: story.id),
                kick: reactionKick
            ) {
                Haptics.tap()
                store.toggleReaction(story.id)
                kickReaction()
            }

            actionTile(
                systemImage: story.isFollowed ? "checkmark" : "ant.fill",
                label: story.isFollowed ? "FOLLOWING" : "FOLLOW\nTHIS FLY",
                isActive: story.isFollowed,
                kick: followKick
            ) {
                Haptics.tap()
                store.toggleFollow(story.id)
                kickFollow()
            }

            actionTile(systemImage: "link", label: "CONNECTIONS", isActive: false, kick: false) {
                Haptics.tap()
                showConnections = true
            }

            actionTile(systemImage: "flag.fill", label: "REPORT", isActive: false, kick: false) {
                Haptics.tap()
                showReport = true
            }
        }
    }

    private func actionTile(
        emoji: String? = nil,
        systemImage: String? = nil,
        label: String,
        isActive: Bool,
        kick: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Group {
                    if let emoji {
                        Text(emoji).font(.system(size: 22))
                    } else if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(isActive ? WallTheme.rust : WallTheme.ink)
                    }
                }
                .scaleEffect(kick ? 1.35 : 1)

                Text(label)
                    .font(WallFont.stamp(10))
                    .foregroundStyle(isActive ? WallTheme.rust : WallTheme.ink.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .padding(.horizontal, 4)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(WallTheme.paper.opacity(0.93))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? WallTheme.rust.opacity(0.8) : WallTheme.inkSoft.opacity(0.45), lineWidth: isActive ? 2 : 1.2)
                    )
            }
            .wallShadow(radius: 6, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
    }

    private func witnessNotes(_ story: StoryFly) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT THE WITNESSES SAID")
                .font(WallFont.stencil(16))
                .foregroundStyle(WallTheme.paper)
                .shadow(color: .black.opacity(0.5), radius: 3)

            ForEach(store.claims(for: story.id)) { claim in
                TapedPaper(rotation: 0.6, padding: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Image(systemName: claim.angle.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(claim.angle.rawValue.uppercased())
                                .font(WallFont.stamp(11))
                        }
                        .foregroundStyle(WallTheme.rust)
                        if !claim.note.isEmpty {
                            Text(claim.note)
                                .font(WallFont.marker(14, weight: .regular))
                                .foregroundStyle(WallTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    /// Short scale pop on the laugh icon.
    private func kickReaction() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { reactionKick = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { reactionKick = false }
        }
    }

    /// Short scale pop on the follow icon.
    private func kickFollow() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) { followKick = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { followKick = false }
        }
    }
}
