//
//  BuzzDetailScreen.swift
//  FlyOnAWall
//
//  One Buzz, spread across taped paper: who posted it (the Fly), the text,
//  tags, stats, Buzz Backs, witness notes, and the action row. Owns the bottom
//  edge with the I WAS THERE plate.
//

import SwiftUI

struct BuzzDetailScreen: View {
    let buzzID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWitnessSheet: Bool = false
    @State private var showBuzzBackSheet: Bool = false
    @State private var showReport: Bool = false
    @State private var reactionKick: Bool = false
    @State private var followKick: Bool = false

    private var buzz: Buzz? { store.buzz(id: buzzID) }
    private var author: FlyProfile? { buzz.flatMap { store.profile(id: $0.authorID) } }
    private var isFollowing: Bool { author.map { store.isFollowing($0.id) } ?? false }

    var body: some View {
        ZStack {
            WallBackdrop(tint: buzz?.category.tint, tintStrength: 0.12)

            if let buzz, let author {
                content(buzz, author)
            } else {
                Text("This buzz flew off.")
                    .font(WallFont.marker(16))
                    .foregroundStyle(WallTheme.inkSoft)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showWitnessSheet) {
            if let buzz {
                IWasThereSheet(buzz: buzz)
            }
        }
        .sheet(isPresented: $showBuzzBackSheet) {
            if let buzz {
                BuzzBackSheet(buzz: buzz)
            }
        }
        .alert("Reported", isPresented: $showReport) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thanks. A fly will look into it.")
        }
    }

    private func content(_ buzz: Buzz, _ author: FlyProfile) -> some View {
        VStack(spacing: 0) {
            HStack {
                BackChip { path.removeLast() }
                Spacer()
                Text("\(buzz.category.emoji) \(buzz.category.title)")
                    .font(WallFont.stamp(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(buzz.category.tint))
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)

            ScrollView {
                VStack(spacing: 18) {
                    authorCard(buzz, author)
                    buzzCard(buzz)
                    statsRow(buzz)
                    connectionIndicators(buzz)
                    actionGrid(buzz, author)
                    buzzBacksSection(buzz)
                    if !store.claims(for: buzz.id).isEmpty {
                        witnessNotes(buzz)
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
                Text("\(buzz.iWasThereCount) flies say they were there too")
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

    private func authorCard(_ buzz: Buzz, _ author: FlyProfile) -> some View {
        Button {
            Haptics.tap()
            path.append(WallRoute.hive(author.id))
        } label: {
            TapedPaper(rotation: -1.6, padding: 14) {
                HStack(spacing: 12) {
                    FlyView(status: author.currentStatus, size: 30, wingsBeating: false)
                        .frame(width: 48, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.username)
                            .font(WallFont.stencil(18))
                            .foregroundStyle(WallTheme.ink)
                        Text("Posted \(buzz.postedAgo) · \(author.currentStatus.title)")
                            .font(WallFont.marker(12, weight: .regular))
                            .foregroundStyle(WallTheme.inkSoft)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        Image(systemName: "hexagon.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("HIVE")
                            .font(WallFont.stamp(9))
                    }
                    .foregroundStyle(WallTheme.teal)
                }
            }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityLabel("\(author.username)'s hive. \(author.currentStatus.blurb)")
    }

    private func buzzCard(_ buzz: Buzz) -> some View {
        TapedPaper(rotation: 0.8, padding: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text(buzz.text)
                    .font(WallFont.marker(21, weight: .medium))
                    .foregroundStyle(WallTheme.ink)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !buzz.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(buzz.tags, id: \.self) { tag in
                            Text(tag)
                                .font(WallFont.stamp(10))
                                .foregroundStyle(buzz.category.tint)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(buzz.category.tint.opacity(0.12))
                                        .overlay(Capsule().stroke(buzz.category.tint.opacity(0.5), lineWidth: 1))
                                )
                        }
                    }
                }
            }
        }
    }

    private func statsRow(_ buzz: Buzz) -> some View {
        HStack(spacing: 8) {
            stat("\(buzz.reactionCount)", "laughs")
            stat("\(buzz.buzzBackCount)", "buzz backs")
            stat("\(buzz.iWasThereCount)", "i was there")
            stat("\(max(buzz.connectionCount, store.connectedBuzzes(to: buzz).count))", "linked")
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
                .font(WallFont.stamp(10))
                .foregroundStyle(WallTheme.paper.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(WallTheme.ink.opacity(0.62))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.14), lineWidth: 1))
        }
    }

    // MARK: - Connections

    /// 🟣 connected-buzz count + 🪰 swarm membership, when they exist.
    @ViewBuilder
    private func connectionIndicators(_ buzz: Buzz) -> some View {
        let linkCount = store.connections(touching: buzz.id).count
        if linkCount > 0 {
            Button {
                Haptics.tap()
                path.append(WallRoute.connectionBoard(buzz.id))
            } label: {
                HStack(spacing: 11) {
                    Text("🟣")
                        .font(.system(size: 17))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(linkCount) CONNECTED BUZZES")
                            .font(WallFont.stencil(17))
                            .foregroundStyle(WallTheme.ink)
                        Text("THESE BUZZES MAY CONNECT")
                            .font(WallFont.stamp(10))
                            .foregroundStyle(WallTheme.inkSoft)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(FlyStatus.connected.tint)
                }
                .padding(13)
                .frame(minHeight: 52)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(WallTheme.paper.opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FlyStatus.connected.tint.opacity(0.75), lineWidth: 1.8)
                        )
                        .wallShadow(radius: 7, y: 4)
                }
            }
            .buttonStyle(PressableButtonStyle(scale: 0.98))
            .accessibilityLabel("\(linkCount) connected buzzes. These buzzes may connect. Opens the connection board.")
        }

        if let swarm = store.swarm(for: buzz) {
            Button {
                Haptics.tap()
                path.append(WallRoute.swarm(swarm.id))
            } label: {
                HStack(spacing: 11) {
                    Text("🪰")
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PART OF A SWARM")
                            .font(WallFont.stamp(9))
                            .foregroundStyle(WallTheme.rust)
                        Text(swarm.title)
                            .font(WallFont.stencil(16))
                            .foregroundStyle(WallTheme.ink)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(WallTheme.inkSoft)
                }
                .padding(13)
                .frame(minHeight: 52)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(WallTheme.ink.opacity(0.62))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(WallTheme.rust.opacity(0.7), lineWidth: 1.4)
                        )
                }
            }
            .buttonStyle(PressableButtonStyle(scale: 0.98))
            .accessibilityLabel("Part of a swarm: \(swarm.title)")
        }
    }

    // MARK: - Actions

    private func actionGrid(_ buzz: Buzz, _ author: FlyProfile) -> some View {
        HStack(spacing: 10) {
            actionTile(
                emoji: "😂",
                label: "\(buzz.reactionCount)",
                isActive: store.hasReacted(to: buzz.id),
                kick: reactionKick
            ) {
                Haptics.tap()
                store.toggleReaction(buzz.id)
                kickReaction()
            }

            actionTile(
                systemImage: "bubble.left.fill",
                label: "BUZZ\nBACK",
                isActive: false,
                kick: false
            ) {
                Haptics.tap()
                showBuzzBackSheet = true
            }

            actionTile(
                systemImage: isFollowing ? "checkmark" : "ant.fill",
                label: isFollowing ? "FOLLOWING" : "FOLLOW\nFLY",
                isActive: isFollowing,
                kick: followKick
            ) {
                Haptics.tap()
                store.toggleFollow(author.id)
                kickFollow()
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

    // MARK: - Conversation

    private func buzzBacksSection(_ buzz: Buzz) -> some View {
        let backs = store.buzzBacks(for: buzz.id)
        return Group {
            if !backs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    PatchedLabel(text: "THE BUZZ BACKS 💬", size: 16)

                    ForEach(backs) { back in
                        TapedPaper(rotation: Double(abs(back.id.hashValue % 3)) - 1.0, padding: 13) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(back.authorUsername)
                                    .font(WallFont.stamp(11))
                                    .foregroundStyle(WallTheme.rust)
                                Text(back.text)
                                    .font(WallFont.marker(15, weight: .regular))
                                    .foregroundStyle(WallTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func witnessNotes(_ buzz: Buzz) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PatchedLabel(text: "WHAT THE WITNESSES SAID 👀", size: 16)

            ForEach(store.claims(for: buzz.id)) { claim in
                TapedPaper(rotation: 0.6, padding: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Image(systemName: claim.angle.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(claim.angle.rawValue.uppercased())
                                .font(WallFont.stamp(11))
                        }
                        .foregroundStyle(WallTheme.rust)
                        Text(claim.authorUsername)
                            .font(WallFont.stamp(10))
                            .foregroundStyle(WallTheme.inkSoft)
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

    // MARK: - Kicks

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
