//
//  ConnectionBoardScreen.swift
//  FlyOnAWall
//
//  Phase 2: the investigation board. The selected fly sits near the centre,
//  related flies hang around it, and tappable lines hold them together.
//  Everything here relates STORIES — never people.
//

import SwiftUI

// MARK: - Line visuals per strength

extension ConnectionStrength {
    /// Connection colour: purple belongs to linked stories (the connected tint).
    var lineColor: Color {
        switch self {
        case .weakBuzz: WallTheme.inkSoft
        case .possible, .strongBuzz: FlyCategory.connected.tint
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .weakBuzz: 1.6
        case .possible: 3
        case .strongBuzz: 4.5
        }
    }

    var dash: [CGFloat]? {
        switch self {
        case .weakBuzz: [4, 7]
        case .possible: [14, 8]
        case .strongBuzz: nil
        }
    }
}

// MARK: - Screen

struct ConnectionBoardScreen: View {
    let storyID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showConnectFlow: Bool = false
    @State private var clueLink: FlyConnection?
    @State private var inspected: StoryFly?
    @State private var boardAppeared: Bool = false

    private var story: StoryFly? { store.story(id: storyID) }
    private var links: [FlyConnection] { store.connections(touching: storyID) }
    private var swarm: Swarm? { story.flatMap { store.swarm(for: $0) } }

    /// Strongest links hang closest to the focus fly — held tighter.
    private var rankedLinks: [FlyConnection] {
        links.sorted { strengthRank($0.strength) < strengthRank($1.strength) }
    }

    private func strengthRank(_ strength: ConnectionStrength) -> Int {
        switch strength {
        case .strongBuzz: 0
        case .possible: 1
        case .weakBuzz: 2
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let topInset: CGFloat = swarm == nil ? 168 : 258
            let field = CGRect(
                x: 24,
                y: topInset,
                width: size.width - 48,
                height: max(210, size.height - topInset - 124)
            )

            ZStack {
                WallBackdrop(tint: FlyCategory.connected.tint, tintStrength: 0.10)

                if let story {
                    boardLayer(story, field: field)
                    header(story)
                }

                connectButton
            }
            .onAppear {
                guard !boardAppeared else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                    boardAppeared = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showConnectFlow) {
            ConnectFlyFlow(focusStoryID: storyID, path: $path)
        }
        .sheet(item: $clueLink) { link in
            ConnectionClueSheet(link: link, focusStoryID: storyID, path: $path)
        }
        .sheet(item: $inspected) { fly in
            FlyInspectorSheet(story: fly, path: $path)
        }
    }

    // MARK: - Board layers

    private func boardLayer(_ story: StoryFly, field: CGRect) -> some View {
        let center = CGPoint(x: field.midX, y: field.midY)

        return ZStack {
            // Lines underneath everything.
            ForEach(Array(rankedLinks.enumerated()), id: \.element.id) { index, link in
                if let partner = store.story(id: link.other(end: story.id)) {
                    let end = anchor(for: index, field: field)
                    lineLayer(from: center, to: end, link: link, index: index)
                    lineNode(link: link, from: center, to: end, index: index)
                    BoardFlyNode(
                        story: partner,
                        rank: index,
                        appeared: boardAppeared
                    ) {
                        Haptics.tap()
                        inspected = partner
                    }
                    .position(end)
                }
            }

            focusNode(story)
                .position(center)

            if rankedLinks.isEmpty {
                emptyState
                    .position(x: center.x, y: center.y + 118)
            }
        }
    }

    /// NO CONNECTIONS YET — this fly still buzzes alone. For now.
    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("NO CONNECTIONS YET")
                .font(WallFont.stencil(18))
                .foregroundStyle(WallTheme.ink)
            Text("This fly buzzes alone. For now.")
                .font(WallFont.marker(13, weight: .regular))
                .foregroundStyle(WallTheme.inkSoft)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(WallTheme.paper.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(WallTheme.inkSoft.opacity(0.4), lineWidth: 1))
        }
        .rotationEffect(.degrees(-2))
        .wallShadow(radius: 7, y: 4)
        .scaleEffect(boardAppeared ? 1 : 0.6)
        .opacity(boardAppeared ? 1 : 0)
    }

    /// Organic sagging line between the focus fly and a related fly.
    private func lineLayer(from: CGPoint, to: CGPoint, link: FlyConnection, index: Int) -> some View {
        let line = ConnectionLine(from: from, to: to, bowSign: index % 2 == 0 ? 1 : -1)
        let glow = ConnectionLine(from: from, to: to, bowSign: index % 2 == 0 ? 1 : -1)
        return ZStack {
            if link.strength == .strongBuzz {
                glow
                    .trim(from: 0, to: boardAppeared ? 1 : 0)
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .foregroundStyle(link.strength.lineColor.opacity(0.16))
            }
            line
                .trim(from: 0, to: boardAppeared ? 1 : 0)
                .stroke(style: StrokeStyle(
                    lineWidth: link.strength.lineWidth,
                    lineCap: .round,
                    dash: link.strength.dash ?? []
                ))
                .foregroundStyle(link.strength.lineColor.opacity(link.strength == .weakBuzz ? 0.55 : 0.85))
        }
        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.08), value: boardAppeared)
        .allowsHitTesting(false)
    }

    /// Small tappable node riding each line — reliable to hit, unlike the hairline.
    private func lineNode(link: FlyConnection, from: CGPoint, to: CGPoint, index: Int) -> some View {
        let control = ConnectionLine.control(from: from, to: to, bowSign: index % 2 == 0 ? 1 : -1)
        let point = bezierPoint(from: from, control: control, to: to, t: 0.62)
        return LineNode(link: link, appeared: boardAppeared) {
            Haptics.tap()
            clueLink = link
        }
        .position(point)
    }

    /// Radial layout, deterministic per story. Strong links sit closest.
    private func anchor(for rank: Int, field: CGRect) -> CGPoint {
        var rng = WallRandom(seed: UInt64(truncatingIfNeeded: Int64(storyID.hashValue &+ rank &* 7919)))
        let count = max(1, rankedLinks.count)
        let spread = count == 1 ? .pi / 2 : (2 * .pi / Double(count))
        let angle = Double(rank) * spread - .pi / 2 + rng.next(in: -0.26...0.26)
        let factor = 0.34 + 0.11 * Double(rank % 4) + rng.next(in: -0.03...0.03)
        return CGPoint(
            x: field.midX + CGFloat(cos(angle)) * field.width / 2 * CGFloat(factor),
            y: field.midY + CGFloat(sin(angle)) * field.height / 2 * CGFloat(factor)
        )
    }

    private func bezierPoint(from: CGPoint, control: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * from.x + 2 * u * t * control.x + t * t * to.x,
            y: u * u * from.y + 2 * u * t * control.y + t * t * to.y
        )
    }

    private func focusNode(_ story: StoryFly) -> some View {
        VStack(spacing: 3) {
            FlyView(category: story.category, size: 46)
            Text(story.handle)
                .font(WallFont.stamp(11))
                .foregroundStyle(WallTheme.ink)
            Text("THIS FLY")
                .font(WallFont.stamp(8))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(FlyCategory.connected.tint))
        }
        .padding(14)
        .background {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FlyCategory.connected.tint.opacity(0.20), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 96
                    )
                )
                .frame(width: 180, height: 180)
        }
        .scaleEffect(boardAppeared ? 1 : 0.4)
        .opacity(boardAppeared ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.handle). Focus of this board. \(story.text)")
    }

    // MARK: - Chrome

    private func header(_ story: StoryFly) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            BackChip { path.removeLast() }

            StencilTitle(text: "CONNECTION BOARD", size: 27)
            Text("STORIES MAY CONNECT. PEOPLE ARE NEVER IDENTIFIED.")
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.ink.opacity(0.75))

            if let swarm {
                swarmBanner(swarm)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(headerBlocksTouches)
    }

    /// Touches pass through the empty part of the header so board nodes near
    /// the top stay tappable; the banner itself stays interactive.
    private var headerBlocksTouches: Bool { swarm != nil }

    private func swarmBanner(_ swarm: Swarm) -> some View {
        let stats = store.connectionStats(for: swarm)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("🪰").font(.system(size: 14))
                Text("PART OF A SWARM")
                    .font(WallFont.stamp(10))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(FlyCategory.connected.tint))
            }
            Text(swarm.title)
                .font(WallFont.stencil(21))
                .foregroundStyle(WallTheme.ink)
            Text("\(swarm.flyCount) FLIES · \(stats.strong) STRONG · \(stats.possible) POSSIBLE")
                .font(WallFont.stamp(11))
                .foregroundStyle(WallTheme.inkSoft)

            Button {
                Haptics.tap()
                path.append(WallRoute.swarm(swarm.id))
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "link")
                        .font(.system(size: 13, weight: .heavy))
                    Text("ENTER THE SWARM")
                        .font(WallFont.stamp(13))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(WallTheme.ink.opacity(0.85))
                        .overlay(Capsule().stroke(FlyCategory.connected.tint.opacity(0.9), lineWidth: 1.6))
                )
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.paper.opacity(0.93))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.2))
                .wallShadow(radius: 8, y: 4)
        }
    }

    /// Legend scrap showing what each line weight means.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(.strongBuzz)
            legendRow(.possible)
            legendRow(.weakBuzz)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(WallTheme.paper.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(WallTheme.inkSoft.opacity(0.35), lineWidth: 1))
        }
        .wallShadow(radius: 5, y: 3)
        .allowsHitTesting(false)
    }

    private func legendRow(_ strength: ConnectionStrength) -> some View {
        HStack(spacing: 7) {
            ConnectionLine(from: CGPoint(x: 0, y: 6), to: CGPoint(x: 40, y: 6), bowSign: 0)
                .stroke(style: StrokeStyle(lineWidth: strength.lineWidth, lineCap: .round, dash: strength.dash ?? []))
                .foregroundStyle(strength.lineColor.opacity(0.9))
                .frame(width: 40, height: 12)
            Text(strength.title)
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.ink.opacity(0.85))
        }
    }

    private var connectButton: some View {
        VStack(spacing: 6) {
            PlateButton(title: "CONNECT A FLY", systemImage: "link") {
                Haptics.tap()
                showConnectFlow = true
            }
            Text("Propose that two flies may be talking about the same thing.")
                .font(WallFont.stamp(9))
                .foregroundStyle(WallTheme.paper.opacity(0.85))
                .shadow(color: .black.opacity(0.55), radius: 3)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .overlay(alignment: .bottomLeading) {
            legend.padding(.leading, 18).padding(.bottom, 96)
        }
    }
}

// MARK: - Shapes

/// Slightly bowed line so the board reads as string-and-pin, not a chart.
struct ConnectionLine: Shape {
    let from: CGPoint
    let to: CGPoint
    /// -1/0/1: which way the line sags.
    let bowSign: CGFloat

    static func control(from: CGPoint, to: CGPoint, bowSign: CGFloat) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let bow = length * 0.10 * bowSign
        return CGPoint(x: (from.x + to.x) / 2 - dy / length * bow, y: (from.y + to.y) / 2 + dx / length * bow)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addQuadCurve(to: to, control: Self.control(from: from, to: to, bowSign: bowSign))
        return path
    }
}

// MARK: - Board nodes

/// One related fly hovering gently at the end of a line.
private struct BoardFlyNode: View {
    let story: StoryFly
    let rank: Int
    let appeared: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hover: Bool = false
    @State private var wobble: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                FlyView(category: story.category, size: 26)
                Text(story.handle)
                    .font(WallFont.stamp(9))
                    .foregroundStyle(WallTheme.ink.opacity(0.85))
            }
            .padding(7)
            .frame(minWidth: 60, minHeight: 60)
            .background(Circle().fill(WallTheme.paper.opacity(0.14)))
            .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.9))
        .offset(y: hover ? -4 : 4)
        .rotationEffect(.degrees(wobble ? 2 : -2))
        .scaleEffect(appeared ? 1 : 0.4)
        .opacity(appeared ? 1 : 0)
        .onAppear(perform: startMotion)
        .accessibilityLabel("\(story.handle). \(story.text). Tap to inspect.")
    }

    /// Subtle floating only — the graph must stay readable. No wall wandering.
    private func startMotion() {
        guard !reduceMotion else { return }
        let delay = Double(rank) * 0.18
        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true).delay(delay)) {
            hover = true
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(delay + 0.3)) {
            wobble = true
        }
    }
}

/// The small pin riding each connection line.
private struct LineNode: View {
    let link: FlyConnection
    let appeared: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(WallTheme.paper.opacity(0.96))
                    .overlay(Circle().stroke(link.strength.lineColor.opacity(0.9), lineWidth: 1.6))
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(link.strength.lineColor)
            }
            .frame(width: 28, height: 28)
            .wallShadow(radius: 4, y: 2)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.85))
        .scaleEffect(appeared ? 1 : 0.3)
        .opacity(appeared ? 1 : 0)
        .accessibilityLabel("Why do these flies connect? \(link.strength.title)")
    }
}
