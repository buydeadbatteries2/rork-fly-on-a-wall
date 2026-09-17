//
//  TheWallScreen.swift
//  FlyOnAWall
//
//  Home: a living wall. Not a feed.
//

import SwiftUI

/// A category fly's placement on the wall.
private struct WallSlot: Identifiable {
    let id: String
    let category: FlyCategory
    let unit: CGPoint
    let size: CGFloat
    let seed: UInt64
}

struct TheWallScreen: View {
    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var path: [WallRoute]

    @State private var director = RobotDirector()
    @State private var hasSwatted: Bool = false
    @State private var emphasizedCategory: FlyCategory?
    @State private var announcedCategory: FlyCategory?
    @State private var showLegend: Bool = false
    @State private var swatRipple: Bool = false

    /// Hand-placed so flies avoid the title block and the tab strip.
    private let slots: [WallSlot] = [
        WallSlot(id: "new", category: .new, unit: CGPoint(x: 0.30, y: 0.30), size: 34, seed: 11),
        WallSlot(id: "hot", category: .hot, unit: CGPoint(x: 0.60, y: 0.26), size: 36, seed: 23),
        WallSlot(id: "local", category: .local, unit: CGPoint(x: 0.19, y: 0.44), size: 33, seed: 37),
        WallSlot(id: "question", category: .inQuestion, unit: CGPoint(x: 0.78, y: 0.36), size: 33, seed: 41),
        WallSlot(id: "connected", category: .connected, unit: CGPoint(x: 0.82, y: 0.53), size: 34, seed: 53),
        WallSlot(id: "iwasthere", category: .iWasThere, unit: CGPoint(x: 0.16, y: 0.61), size: 36, seed: 67),
        WallSlot(id: "strong", category: .strongConnection, unit: CGPoint(x: 0.27, y: 0.52), size: 32, seed: 71),
        WallSlot(id: "old", category: .oldBuzz, unit: CGPoint(x: 0.86, y: 0.67), size: 32, seed: 83)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let field = CGRect(
                x: 16,
                y: 150,
                width: size.width - 32,
                height: max(120, size.height - 150 - WallMetrics.tabBarClearance - 10)
            )
            let robotHeight = min(260, size.height * 0.34)
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

                ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                    let home = CGPoint(
                        x: field.minX + field.width * slot.unit.x,
                        y: field.minY + field.height * slot.unit.y
                    )
                    let partner = partnerPoint(for: index, field: field)
                    BuzzingFly(
                        category: slot.category,
                        home: home,
                        bounds: field,
                        size: slot.size,
                        partner: partner,
                        seed: slot.seed,
                        isEmphasized: emphasizedCategory == slot.category,
                        entranceFrom: hasSwatted ? nil : robotAnchor,
                        entranceDelay: 0.45 + Double(index) * 0.045,
                        director: director,
                        accessibilityTitle: "\(slot.category.title) flies. \(store.count(for: slot.category)) stories. \(slot.category.blurb)"
                    ) {
                        tap(slot.category)
                    }
                }

                header

                if let announced = announcedCategory {
                    categoryStamp(announced)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
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
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    StencilTitle(text: "FLY ON", size: 44)
                    StencilTitle(text: "A WALL", size: 44)
                    Text("Small flies. Big stories.")
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
                FlyView(category: .oldBuzz, size: 22, wingsBeating: false)
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

    private func wallGraffiti(size: CGSize) -> some View {
        ZStack {
            Text("EVERY\nWALL HAS\nA STORY.")
                .font(WallFont.stencil(19))
                .foregroundStyle(WallTheme.teal.opacity(0.85))
                .multilineTextAlignment(.leading)
                .rotationEffect(.degrees(-3))
                .position(x: size.width * 0.78, y: size.height * 0.20)

            VStack(spacing: 2) {
                Text("STAY")
                Text("AWKWARD")
            }
            .font(WallFont.stencil(15))
            .foregroundStyle(WallTheme.rust.opacity(0.8))
            .rotationEffect(.degrees(-5))
            .position(x: size.width * 0.18, y: size.height * 0.80)

            Text("GOOD FLIES\nBAD IDEAS")
                .font(WallFont.stamp(12))
                .foregroundStyle(WallTheme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(6))
                .position(x: size.width * 0.86, y: size.height * 0.78)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func categoryStamp(_ category: FlyCategory) -> some View {
        VStack(spacing: 6) {
            Text(category.title)
                .font(WallFont.stencil(34))
                .kerning(1.5)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(category.blurb)
                .font(WallFont.marker(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(category.tint.opacity(category == .strongConnection ? 0.55 : 0.85))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(WallTheme.ink.opacity(0.6), lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
        }
        .rotationEffect(.degrees(-3))
    }

    // MARK: - Behaviour

    private func partnerPoint(for index: Int, field: CGRect) -> CGPoint? {
        let partnerSlot = slots[(index + 1) % slots.count]
        return CGPoint(
            x: field.minX + field.width * partnerSlot.unit.x,
            y: field.minY + field.height * partnerSlot.unit.y
        )
    }

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

    /// Small chance the robot laughs when the user returns after reacting to or
    /// following a HOT fly. Deliberately lightweight — no extra state machinery.
    private func maybeCelebrate() {
        let hotEngaged = store.followedFlies.contains { $0.category == .hot }
            || store.stories.contains { $0.category == .hot && store.reactedIDs.contains($0.id) }
        guard hotEngaged, Double.random(in: 0...1) < 0.4 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            director.celebrate()
        }
    }

    private func tap(_ category: FlyCategory) {
        guard emphasizedCategory == nil else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            emphasizedCategory = category
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65).delay(0.1)) {
            announcedCategory = category
        }
        let hold: Double = reduceMotion ? 0.35 : 0.7
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            withAnimation(.easeOut(duration: 0.2)) {
                emphasizedCategory = nil
                announcedCategory = nil
            }
            path.append(WallRoute.category(category))
        }
    }
}
