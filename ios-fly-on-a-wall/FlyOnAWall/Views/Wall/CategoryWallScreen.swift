//
//  CategoryWallScreen.swift
//  FlyOnAWall
//
//  A category is another section of the wall, filled with story flies.
//

import SwiftUI

struct CategoryWallScreen: View {
    let category: FlyCategory
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var emphasizedID: String?

    private var stories: [StoryFly] { store.stories(in: category) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let field = CGRect(
                x: 18,
                y: 132,
                width: size.width - 36,
                height: max(140, size.height - 132 - WallMetrics.tabBarClearance - 16)
            )

            ZStack {
                WallBackdrop(tint: category.tint, tintStrength: category == .strongConnection ? 0.10 : 0.22)

                sideNotes(size: size)

                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    let placement = placement(index: index, count: stories.count, field: field)
                    let partner = partnerPoint(index: index, count: stories.count, field: field)
                    BuzzingFly(
                        category: category,
                        home: placement.point,
                        bounds: field,
                        size: placement.size,
                        partner: partner,
                        seed: UInt64(index &* 977 &+ 13),
                        isEmphasized: emphasizedID == story.id,
                        showsConnectionMark: !store.connections(touching: story.id).isEmpty,
                        accessibilityTitle: "\(story.handle). \(story.text)"
                    ) {
                        tap(story)
                    }
                }

                header
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                BackChip { path.removeLast() }
                Spacer(minLength: 0)
                Text("\(stories.count) FLIES")
                    .font(WallFont.stamp(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(WallTheme.ink.opacity(0.7)))
            }

            VStack(alignment: .leading, spacing: 2) {
                StencilTitle(text: category.title, size: category.title.count > 12 ? 30 : 40)
                Text(category.blurb)
                    .font(WallFont.marker(14))
                    .foregroundStyle(WallTheme.ink.opacity(0.85))
                    .shadow(color: WallTheme.bone.opacity(0.6), radius: 0, x: 1, y: 1)
                Text("Tap a fly to follow it somewhere private.")
                    .font(WallFont.stamp(11))
                    .foregroundStyle(WallTheme.inkSoft)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    private func sideNotes(size: CGSize) -> some View {
        ZStack {
            Text("SAME PLACES.\nDIFFERENT\nSTORIES.")
                .font(WallFont.stamp(12))
                .foregroundStyle(WallTheme.ink.opacity(0.5))
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(5))
                .position(x: size.width * 0.84, y: size.height * 0.30)

            Text("GOOD STORIES\nSTICK AROUND.")
                .font(WallFont.stencil(15))
                .foregroundStyle(WallTheme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(-3))
                .position(x: size.width * 0.74, y: size.height * 0.80)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Layout

    /// Golden-angle scatter keeps flies spread without overlapping clusters.
    private func placement(index: Int, count: Int, field: CGRect) -> (point: CGPoint, size: CGFloat) {
        var rng = WallRandom(seed: UInt64(index &* 7919 &+ 31))
        let columns = 3
        let rows = max(1, Int(ceil(Double(count) / Double(columns))))
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
        let size = CGFloat(rng.next(in: 30...44))
        return (point, size)
    }

    private func partnerPoint(index: Int, count: Int, field: CGRect) -> CGPoint? {
        guard count > 1 else { return nil }
        return placement(index: (index + 1) % count, count: count, field: field).point
    }

    private func tap(_ story: StoryFly) {
        guard emphasizedID == nil else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            emphasizedID = story.id
        }
        let hold: Double = reduceMotion ? 0.2 : 0.42
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            emphasizedID = nil
            path.append(WallRoute.story(story.id))
        }
    }
}

/// Themed back control used on pushed wall screens.
struct BackChip: View {
    var title: String = "BACK"
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .black))
                Text(title)
                    .font(WallFont.stamp(12))
            }
            .foregroundStyle(WallTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minHeight: 44)
            .background {
                Capsule()
                    .fill(WallTheme.paper.opacity(0.92))
                    .overlay(Capsule().stroke(WallTheme.inkSoft.opacity(0.5), lineWidth: 1.2))
            }
            .wallShadow(radius: 5, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Back")
    }
}
