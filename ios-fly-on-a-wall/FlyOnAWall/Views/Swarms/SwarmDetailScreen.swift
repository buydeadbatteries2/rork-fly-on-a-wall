//
//  SwarmDetailScreen.swift
//  FlyOnAWall
//
//  One swarm: the flies that circle a single event.
//

import SwiftUI

struct SwarmDetailScreen: View {
    let swarmID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var emphasizedID: String?

    private var swarm: Swarm? { store.swarms.first { $0.id == swarmID } }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let field = CGRect(
                x: 18,
                y: 156,
                width: size.width - 36,
                height: max(150, size.height - 156 - WallMetrics.tabBarClearance - 16)
            )

            ZStack {
                WallBackdrop(tint: WallTheme.teal, tintStrength: 0.16)

                if let swarm {
                    let flies = store.stories(in: swarm)

                    ForEach(Array(flies.enumerated()), id: \.element.id) { index, fly in
                        let point = orbitPoint(index: index, count: flies.count, field: field)
                        BuzzingFly(
                            category: fly.category,
                            home: point,
                            bounds: field,
                            size: 34,
                            partner: CGPoint(x: field.midX, y: field.midY),
                            seed: UInt64(index &* 613 &+ 7),
                            isEmphasized: emphasizedID == fly.id,
                            showsConnectionMark: !store.connections(touching: fly.id).isEmpty,
                            accessibilityTitle: "\(fly.handle). \(fly.text)"
                        ) {
                            tap(fly)
                        }
                    }

                    header(swarm, count: flies.count)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if let swarm {
                PlateButton(title: "ENTER THE SWARM", systemImage: "link") {
                    Haptics.tap()
                    openBoard(for: swarm)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, WallMetrics.tabBarClearance - 18)
            }
        }
    }

    /// The fly with the most links anchors the swarm's Connection Board.
    private func openBoard(for swarm: Swarm) {
        let flies = store.stories(in: swarm)
        let anchor = flies.max(by: {
            store.connections(touching: $0.id).count < store.connections(touching: $1.id).count
        })
        guard let anchorID = anchor?.id else { return }
        path.append(WallRoute.connectionBoard(anchorID))
    }

    private func header(_ swarm: Swarm, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                BackChip { path.removeLast() }
                Spacer()
                Text("\(count) FLIES")
                    .font(WallFont.stamp(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(WallTheme.ink.opacity(0.7)))
            }

            VStack(alignment: .leading, spacing: 3) {
                StencilTitle(text: swarm.title, size: swarm.title.count > 18 ? 26 : 32)
                Text(swarm.teaser)
                    .font(WallFont.marker(14))
                    .foregroundStyle(WallTheme.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: WallTheme.bone.opacity(0.55), radius: 0, x: 1, y: 1)
                connectionLine(for: swarm)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    /// Connection strength summary, e.g. "3 STRONG · 1 POSSIBLE".
    @ViewBuilder
    private func connectionLine(for swarm: Swarm) -> some View {
        let stats = store.connectionStats(for: swarm)
        if stats.strong + stats.possible + stats.weak > 0 {
            Text("\(stats.strong) STRONG · \(stats.possible) POSSIBLE · \(stats.weak) WEAK")
                .font(WallFont.stamp(11))
                .foregroundStyle(FlyCategory.connected.tint)
                .padding(.top, 2)
        }
    }

    /// Flies orbit the event at the centre of the field.
    private func orbitPoint(index: Int, count: Int, field: CGRect) -> CGPoint {
        guard count > 0 else { return CGPoint(x: field.midX, y: field.midY) }
        var rng = WallRandom(seed: UInt64(index &* 443 &+ 19))
        let ring = index % 2 == 0 ? 0.62 : 0.34
        let angle = (Double(index) / Double(count)) * 2 * .pi + rng.next(in: -0.3...0.3)
        return CGPoint(
            x: field.midX + CGFloat(cos(angle)) * field.width * 0.5 * CGFloat(ring),
            y: field.midY + CGFloat(sin(angle)) * field.height * 0.46 * CGFloat(ring)
        )
    }

    private func tap(_ fly: StoryFly) {
        guard emphasizedID == nil else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            emphasizedID = fly.id
        }
        let hold: Double = reduceMotion ? 0.2 : 0.42
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            emphasizedID = nil
            path.append(WallRoute.story(fly.id))
        }
    }
}
