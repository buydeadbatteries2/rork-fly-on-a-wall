//
//  SwarmsScreen.swift
//  FlyOnAWall
//
//  THE SWARMS — clusters of flies circling one event.
//

import SwiftUI

struct SwarmsScreen: View {
    @Binding var path: [WallRoute]
    @Environment(WallStore.self) private var store

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.teal, tintStrength: 0.14)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "THE SWARMS", size: 42)
                        Text("When too many flies circle the same night.")
                            .font(WallFont.marker(15))
                            .foregroundStyle(WallTheme.ink.opacity(0.85))
                            .shadow(color: WallTheme.bone.opacity(0.5), radius: 0, x: 1, y: 1)
                    }
                    .padding(.top, 8)

                    ForEach(store.swarms) { swarm in
                        SwarmClusterCard(swarm: swarm) {
                            Haptics.tap()
                            path.append(WallRoute.swarm(swarm.id))
                        }
                    }

                    Color.clear.frame(height: WallMetrics.tabBarClearance)
                }
                .padding(.horizontal, 18)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// A swarm shown as a live cluster of flies on a scrap of wall, not a feed card.
struct SwarmClusterCard: View {
    let swarm: Swarm
    let action: () -> Void

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [WallTheme.warmGray.opacity(0.55), WallTheme.ink.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(WallTheme.ink.opacity(0.45), lineWidth: 1.4))

                    GeometryReader { proxy in
                        let field = CGRect(origin: .zero, size: proxy.size).insetBy(dx: 22, dy: 16)
                        ForEach(Array(swarm.categories.prefix(8).enumerated()), id: \.offset) { index, category in
                            let point = clusterPoint(index: index, count: min(swarm.categories.count, 8), field: field)
                            BuzzingFly(
                                category: category,
                                home: point,
                                bounds: field,
                                size: 24,
                                partner: CGPoint(x: field.midX, y: field.midY),
                                seed: UInt64(abs(swarm.id.hashValue % 9000) + index * 31),
                                accessibilityTitle: "\(category.title) fly in \(swarm.title)"
                            ) {
                                action()
                            }
                            .allowsHitTesting(false)
                        }
                    }
                }
                .frame(height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    Text(swarm.title)
                        .font(WallFont.stencil(24))
                        .foregroundStyle(WallTheme.ink)
                        .multilineTextAlignment(.leading)
                    Text(swarm.teaser)
                        .font(WallFont.marker(14, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Image(systemName: "ant.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(swarm.flyCount) CONNECTED FLIES")
                            .font(WallFont.stamp(11))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(WallTheme.rust))
                    .padding(.top, 2)

                    connectionSummary(swarm)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WallTheme.paper.opacity(0.94))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WallTheme.ink.opacity(0.4), lineWidth: 1.5))
            .wallShadow(radius: 12, y: 7)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(swarm.title). \(swarm.flyCount) connected flies. \(swarm.teaser)")
    }

    /// "3 STRONG · 1 POSSIBLE" — hidden entirely when nothing overlaps.
    @ViewBuilder
    private func connectionSummary(_ swarm: Swarm) -> some View {
        let stats = store.connectionStats(for: swarm)
        if stats.strong + stats.possible + stats.weak > 0 {
            Text("\(stats.strong) STRONG · \(stats.possible) POSSIBLE · \(stats.weak) WEAK")
                .font(WallFont.stamp(10))
                .foregroundStyle(FlyCategory.connected.tint)
                .padding(.top, 4)
        }
    }

    private func clusterPoint(index: Int, count: Int, field: CGRect) -> CGPoint {
        guard count > 0 else { return CGPoint(x: field.midX, y: field.midY) }
        let angle = (Double(index) / Double(count)) * 2 * .pi
        let radiusX = field.width * 0.32
        let radiusY = field.height * 0.30
        return CGPoint(
            x: field.midX + CGFloat(cos(angle)) * radiusX,
            y: field.midY + CGFloat(sin(angle)) * radiusY
        )
    }
}
