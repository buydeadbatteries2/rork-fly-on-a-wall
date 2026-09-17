//
//  WallTabBar.swift
//  FlyOnAWall
//

import SwiftUI
import UIKit

/// Top level destinations.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case wall
    case swarms
    case post
    case explore
    case hive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wall: "THE WALL"
        case .swarms: "SWARMS"
        case .post: "POST A FLY"
        case .explore: "EXPLORE"
        case .hive: "MY HIVE"
        }
    }

    var icon: String {
        switch self {
        case .wall: "square.grid.3x3.fill"
        case .swarms: "circle.hexagongrid.fill"
        case .post: "plus"
        case .explore: "safari.fill"
        case .hive: "hexagon.fill"
        }
    }
}

/// Bottom navigation styled as a scratched metal sign strip bolted to the wall.
struct WallTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                if tab == .post {
                    centerItem(tab)
                } else {
                    item(tab)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: WallMetrics.tabBarHeight)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                WallTheme.warmGray.opacity(0.97),
                                Color(red: 0.60, green: 0.56, blue: 0.47).opacity(0.97)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(WallTheme.ink.opacity(0.55), lineWidth: 1.5)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
                    .blur(radius: 1)
                    .padding(1)
                scratches
            }
            .wallShadow(radius: 14, y: 8)
        }
        .overlay(alignment: .topLeading) { bolt.padding(10) }
        .overlay(alignment: .topTrailing) { bolt.padding(10) }
        .overlay(alignment: .bottomLeading) { bolt.padding(10) }
        .overlay(alignment: .bottomTrailing) { bolt.padding(10) }
        .padding(.horizontal, 12)
    }

    private var scratches: some View {
        Canvas { context, size in
            var rng = WallRandom(seed: 4242)
            for _ in 0..<18 {
                var path = Path()
                let x = CGFloat(rng.next(in: 0...Double(size.width)))
                let y = CGFloat(rng.next(in: 0...Double(size.height)))
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + CGFloat(rng.next(in: -22...22)), y: y + CGFloat(rng.next(in: -4...4))))
                context.stroke(path, with: .color(.white.opacity(rng.next(in: 0.04...0.16))), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .allowsHitTesting(false)
    }

    private var bolt: some View {
        Circle()
            .fill(RadialGradient(colors: [WallTheme.bone.opacity(0.9), WallTheme.ink], center: .topLeading, startRadius: 0, endRadius: 6))
            .frame(width: 7, height: 7)
            .allowsHitTesting(false)
    }

    private func item(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            select(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .bold))
                Text(tab.title)
                    .font(WallFont.stamp(10))
                    .kerning(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? WallTheme.rust : WallTheme.ink.opacity(0.62))
            .shadow(color: .white.opacity(0.25), radius: 0, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .frame(height: WallMetrics.tabBarHeight)
            .contentShape(Rectangle())
            .scaleEffect(isSelected ? 1.06 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func centerItem(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            select(tab)
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [WallTheme.rust, WallTheme.rust.opacity(0.75)]
                                    : [WallTheme.ink.opacity(0.85), WallTheme.ink.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1.5))
                        .shadow(color: isSelected ? WallTheme.rust.opacity(0.6) : .black.opacity(0.4), radius: 8, y: 3)
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(.white)
                }
                .offset(y: -10)
                Text(tab.title)
                    .font(WallFont.stamp(10))
                    .kerning(0.4)
                    .foregroundStyle(isSelected ? WallTheme.rust : WallTheme.ink.opacity(0.62))
                    .offset(y: -8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: WallMetrics.tabBarHeight)
            .contentShape(Rectangle())
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func select(_ tab: AppTab) {
        guard selection != tab else { return }
        Haptics.tap()
        selection = tab
    }
}

/// Small haptic helpers used across the app.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func thud() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
