//
//  TheWallScreen.swift
//  FlyOnAWall
//
//  Home: a living wall of blogger Flies, not a feed. Each fly is a FlyProfile;
//  colour reflects that Fly's current Buzz status; the sticker selector filters
//  by Buzz category.
//

import SwiftUI

struct TheWallScreen: View {
    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var path: [WallRoute]

    @State private var director = RobotDirector()
    @State private var hasSwatted: Bool = false
    @State private var selectedCategory: BuzzCategory?
    @State private var selectedFly: FlyProfile?
    @State private var showPreview: Bool = false
    @State private var showLegend: Bool = false
    @State private var swatRipple: Bool = false

    /// Bloggers on the wall right now — filtered by the category selector.
    private var flies: [FlyProfile] { store.flies(for: selectedCategory) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let field = CGRect(
                x: 16,
                y: 208,
                width: size.width - 32,
                height: max(150, size.height - 208 - WallMetrics.tabBarClearance - 4)
            )
            let robotHeight = min(250, size.height * 0.32)
            let robotAnchor = CGPoint(x: size.width * 0.52, y: size.height - WallMetrics.tabBarClearance - robotHeight * 0.52)

            // Give the robot's brain its body: head position for "who's near me"
            // and a perch just above the head for the landing gag.
            let _ = director.syncScene(
                reduceMotion: reduceMotion,
                head: CGPoint(x: robotAnchor.x, y: robotAnchor.y - robotHeight * 0.22),
                perch: CGPoint(x: robotAnchor.x + robotHeight * 0.10, y: robotAnchor.y - robotHeight * 0.42)
            )

            ZStack {
                WallBackdrop()

                wallGraffiti(size: size)

                StinkyRobotView(director: director, height: robotHeight)
                    .position(x: robotAnchor.x, y: robotAnchor.y)

                if swatRipple {
                    Circle()
                        .stroke(WallTheme.bone.opacity(0.5), lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .scaleEffect(swatRipple ? 1.6 : 0.2)
                        .opacity(swatRipple ? 0 : 0.8)
                        .position(robotAnchor)
                        .allowsHitTesting(false)
                }

                ForEach(Array(flies.enumerated()), id: \.element.id) { index, fly in
                    let placement = placement(index: index, count: flies.count, field: field)
                    let partner = partnerPoint(index: index, count: flies.count, field: field)
                    let isSelected = selectedFly?.id == fly.id
                    BuzzingFly(
                        status: fly.currentStatus,
                        home: placement.point,
                        bounds: field,
                        size: placement.size,
                        partner: partner,
                        seed: UInt64(abs(fly.id.hashValue % 9000) &+ index &* 31),
                        isEmphasized: isSelected,
                        isPaused: isSelected,
                        entranceFrom: hasSwatted ? nil : robotAnchor,
                        entranceDelay: 0.45 + Double(index) * 0.035,
                        director: director,
                        username: fly.username,
                        accessibilityTitle: "\(fly.username). \(fly.currentStatus.title). \(fly.followerDisplay) followers. \(fly.currentStatus.blurb)"
                    ) {
                        tap(fly)
                    }
                }

                header

                categorySelector(size: size)
            }
            .onAppear {
                director.reduceMotion = reduceMotion
                runOpeningSwat()
            }
            .onDisappear { director.stop() }
            .onChange(of: reduceMotion) { _, newValue in
                director.reduceMotion = newValue
            }
            .onChange(of: director.swatToken) { _, _ in
                playSwatFX()
            }
        }
        .sheet(isPresented: $showLegend) {
            FlyLegendSheet()
        }
        .sheet(isPresented: $showPreview, onDismiss: clearSelection) {
            if let selected = selectedFly {
                FlyPreviewSheet(fly: selected, path: $path)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    StencilTitle(text: "FLY ON", size: 44)
                    StencilTitle(text: "A WALL", size: 44)
                    Text("Every fly is hiding something.")
                        .font(WallFont.marker(15))
                        .foregroundStyle(WallTheme.ink.opacity(0.8))
                        .padding(.top, 4)
                        .shadow(color: WallTheme.bone.opacity(0.6), radius: 0, x: 1, y: 1)
                }
                Spacer(minLength: 8)
                legendButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var legendButton: some View {
        Button {
            Haptics.tap()
            showLegend = true
        } label: {
            VStack(spacing: 2) {
                FlyView(status: .oldBuzz, size: 22, wingsBeating: false)
                    .frame(height: 26)
                Text("?")
                    .font(WallFont.stencil(20))
                    .foregroundStyle(WallTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 56, minHeight: 56)
            .background {
                ZStack {
                    if let image = UIImage(named: WallAsset.paper) {
                        Image(uiImage: image).resizable()
                    } else {
                        RoundedRectangle(cornerRadius: 3).fill(WallTheme.paper)
                    }
                }
                .allowsHitTesting(false)
            }
            .rotationEffect(.degrees(4))
            .wallShadow(radius: 6, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Know your flies")
    }

    /// Buzz category stickers — taped labels, not a segmented control.
    private func categorySelector(size: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                selectorChip(title: "ALL BUZZ", emoji: nil, category: nil, index: 0)
                ForEach(Array(BuzzCategory.allCases.enumerated()), id: \.element.id) { index, category in
                    selectorChip(title: category.title, emoji: category.emoji, category: category, index: index + 1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
        }
        .frame(width: size.width)
        .position(x: size.width / 2, y: 176)
    }

    private func selectorChip(title: String, emoji: String?, category: BuzzCategory?, index: Int) -> some View {
        let isActive = selectedCategory == category
        let rotation: Double = index % 2 == 0 ? -1.5 : 1.5
        return Button {
            Haptics.tap()
            guard selectedCategory != category else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
                selectedFly = nil
                showPreview = false
            }
        } label: {
            HStack(spacing: 5) {
                if let emoji {
                    Text(emoji).font(.system(size: 13))
                }
                Text(title)
                    .font(WallFont.stamp(11))
                    .kerning(0.5)
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? WallTheme.rust : WallTheme.paper.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isActive ? WallTheme.ink.opacity(0.55) : WallTheme.inkSoft.opacity(0.45), lineWidth: 1.3)
                    )
            }
            .wallShadow(radius: 5, y: 3)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
        .rotationEffect(.degrees(rotation))
        .accessibilityLabel("\(category?.title ?? "All buzz") category filter")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private func wallGraffiti(size: CGSize) -> some View {
        ZStack {
            Text("EVERY\nFLY HAS\nA HIVE.")
                .font(WallFont.stencil(19))
                .foregroundStyle(WallTheme.teal.opacity(0.85))
                .multilineTextAlignment(.leading)
                .rotationEffect(.degrees(-3))
                .position(x: size.width * 0.80, y: size.height * 0.24)

            VStack(spacing: 2) {
                Text("STAY")
                Text("AWKWARD")
            }
            .font(WallFont.stencil(15))
            .foregroundStyle(WallTheme.rust.opacity(0.8))
            .rotationEffect(.degrees(-5))
            .position(x: size.width * 0.16, y: size.height * 0.82)

            Text("GOOD FLIES\nBAD IDEAS")
                .font(WallFont.stamp(12))
                .foregroundStyle(WallTheme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(6))
                .position(x: size.width * 0.85, y: size.height * 0.80)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Layout

    /// Grid with jitter keeps up to 15 blogger flies spread and readable.
    private func placement(index: Int, count: Int, field: CGRect) -> (point: CGPoint, size: CGFloat) {
        var rng = WallRandom(seed: UInt64(index &* 7919 &+ 31))
        let columns = 4
        let rows = max(1, Int(ceil(Double(max(count, 1)) / Double(columns))))
        let col = index % columns
        let row = index / columns
        let cellW = field.width / CGFloat(columns)
        let cellH = field.height / CGFloat(rows)
        let jitterX = CGFloat(rng.next(in: 0.22...0.78))
        let jitterY = CGFloat(rng.next(in: 0.25...0.75))
        let point = CGPoint(
            x: field.minX + cellW * (CGFloat(col) + jitterX),
            y: field.minY + cellH * (CGFloat(row) + jitterY)
        )
        let size = CGFloat(rng.next(in: 28...38))
        return (point, size)
    }

    private func partnerPoint(index: Int, count: Int, field: CGRect) -> CGPoint? {
        guard count > 1 else { return nil }
        return placement(index: (index + 1) % count, count: count, field: field).point
    }

    // MARK: - Behaviour

    /// Opening beat: the robot swats, flies scatter, then settle.
    private func runOpeningSwat() {
        if hasSwatted {
            // Returning to The Wall: restart the brain, maybe celebrate gossip.
            director.start()
            maybeCelebrate()
            return
        }
        let delay: Double = reduceMotion ? 0.1 : 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            director.openingSwat()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                hasSwatted = true
                director.start()
            }
        }
    }

    /// Swat feedback shared by the opening beat, idle swats and the gag.
    private func playSwatFX() {
        Haptics.thud()
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.6)) { swatRipple = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            swatRipple = false
        }
    }

    /// Small chance the robot laughs when the user returns after engaging a
    /// HOT Fly. Deliberately lightweight — no extra state machinery.
    private func maybeCelebrate() {
        let hotEngaged = store.followedFlies.contains { $0.currentStatus == .hot }
            || store.reactedIDs.contains { id in
                store.buzz(id: id).flatMap { store.profile(id: $0.authorID) }?.currentStatus == .hot
            }
        guard hotEngaged, Double.random(in: 0...1) < 0.4 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            director.celebrate()
        }
    }

    /// Tapping a blogger fly: emphasize, pause the movement, show the handle,
    /// then present their current Buzz preview.
    private func tap(_ fly: FlyProfile) {
        guard selectedFly == nil else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            selectedFly = fly
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.3)) {
            showPreview = true
        }
    }

    private func clearSelection() {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedFly = nil
        }
    }
}
