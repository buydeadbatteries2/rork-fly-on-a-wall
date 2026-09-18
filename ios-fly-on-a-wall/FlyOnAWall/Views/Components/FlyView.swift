//
//  FlyView.swift
//  FlyOnAWall
//
//  The reusable robotic fly. Purely visual — movement lives in BuzzingFly.
//

import SwiftUI

/// A single robotic fly rendered from vector parts so every status can differ
/// by colour, wing silhouette, stamped symbol and glow. The colour reflects
/// the Fly's CURRENT BUZZ STATUS, not its identity.
struct FlyView: View {
    let status: FlyStatus
    var size: CGFloat = 34
    var wingsBeating: Bool = true
    var isEmphasized: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flap: Bool = false
    @State private var halo: Bool = false

    private var bodyWidth: CGFloat { size }
    private var bodyHeight: CGFloat { size * 0.62 }

    var body: some View {
        ZStack {
            haloLayer
            wings
            chassis
            legs
        }
        .frame(width: size * 1.5, height: size * 1.3)
        .onAppear(perform: startAnimations)
    }

    private func startAnimations() {
        if wingsBeating && !reduceMotion {
            let beat: Double = status.motion.wingBeat
            withAnimation(.easeInOut(duration: beat).repeatForever(autoreverses: true)) {
                flap = true
            }
        }
        let pulse: Double = reduceMotion ? 2.4 : 1.1
        withAnimation(.easeInOut(duration: pulse).repeatForever(autoreverses: true)) {
            halo = true
        }
    }

    // MARK: - Halo

    @ViewBuilder
    private var haloLayer: some View {
        if status.motion.pulses || isEmphasized {
            let diameter: CGFloat = size * 2.0
            let strength: Double = isEmphasized ? 0.55 : 0.34
            let gradient = RadialGradient(
                colors: [status.glow.opacity(strength), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.95
            )
            Circle()
                .fill(gradient)
                .frame(width: diameter, height: diameter)
                .scaleEffect(halo ? 1.12 : 0.86)
                .opacity(halo ? 1.0 : 0.6)
        }
    }

    // MARK: - Wings

    private var wings: some View {
        let offsetX: CGFloat = bodyWidth * 0.18
        let offsetY: CGFloat = -bodyHeight * 0.42
        return ZStack {
            wingShape
                .rotationEffect(.degrees(-26), anchor: .bottomTrailing)
                .offset(x: -offsetX, y: offsetY)
            wingShape
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .rotationEffect(.degrees(26), anchor: .bottomLeading)
                .offset(x: offsetX, y: offsetY)
        }
        .scaleEffect(y: flap ? 0.62 : 1.0, anchor: .bottom)
    }

    /// Width and height of one wing for the status's silhouette.
    private var wingSize: CGSize {
        switch status.wing {
        case .round: CGSize(width: size * 0.52, height: size * 0.40)
        case .jagged: CGSize(width: size * 0.56, height: size * 0.30)
        case .narrow: CGSize(width: size * 0.44, height: size * 0.24)
        case .tattered: CGSize(width: size * 0.50, height: size * 0.34)
        case .double: CGSize(width: size * 0.48, height: size * 0.36)
        case .long: CGSize(width: size * 0.70, height: size * 0.26)
        }
    }

    private var wingShape: some View {
        let dimensions: CGSize = wingSize
        let w: CGFloat = dimensions.width
        let h: CGFloat = dimensions.height
        let membrane = LinearGradient(
            colors: [Color.white.opacity(0.78), status.glow.opacity(0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let edgeWidth: CGFloat = max(0.6, size * 0.022)

        return ZStack {
            Ellipse()
                .fill(membrane)
                .frame(width: w, height: h)
                .overlay {
                    Ellipse().stroke(WallTheme.ink.opacity(0.35), lineWidth: edgeWidth)
                }

            wingDetail(w: w, h: h)
        }
        .frame(width: w, height: h)
    }

    /// Extra non-colour cue drawn on top of the wing membrane.
    @ViewBuilder
    private func wingDetail(w: CGFloat, h: CGFloat) -> some View {
        switch status.wing {
        case .double:
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: w * 0.7, height: h * 0.62)
                .offset(x: -w * 0.12, y: h * 0.34)
        case .tattered:
            TatteredNotch()
                .stroke(WallTheme.ink.opacity(0.4), lineWidth: max(0.6, size * 0.02))
                .frame(width: w, height: h)
        case .jagged:
            JaggedVein()
                .stroke(status.tint.opacity(0.75), lineWidth: max(0.7, size * 0.025))
                .frame(width: w, height: h)
        default:
            EmptyView()
        }
    }

    // MARK: - Body

    private var chassis: some View {
        ZStack {
            abdomen
            head.offset(y: -bodyHeight * 0.66)
        }
    }

    private var abdomen: some View {
        let shell = LinearGradient(
            colors: [
                status.tint.opacity(0.95),
                status.tint.opacity(0.55),
                WallTheme.ink.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let outlineWidth: CGFloat = max(0.8, size * 0.03)
        let symbolSize: CGFloat = size * 0.24
        let highlightWidth: CGFloat = bodyWidth * 0.4
        let highlightHeight: CGFloat = bodyHeight * 0.14

        return Ellipse()
            .fill(shell)
            .frame(width: bodyWidth, height: bodyHeight)
            .overlay {
                Ellipse().stroke(WallTheme.ink.opacity(0.7), lineWidth: outlineWidth)
            }
            .overlay {
                Image(systemName: status.symbol)
                    .font(.system(size: symbolSize, weight: .black))
                    .foregroundStyle(plateSymbolColor)
                    .offset(y: bodyHeight * 0.08)
            }
            .overlay {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: highlightWidth, height: highlightHeight)
                    .offset(x: -bodyWidth * 0.14, y: -bodyHeight * 0.26)
            }
    }

    private var head: some View {
        let headSize: CGFloat = size * 0.40
        let plating = LinearGradient(
            colors: [WallTheme.warmGray, WallTheme.ink],
            startPoint: .top,
            endPoint: .bottom
        )
        return ZStack {
            Circle()
                .fill(plating)
                .frame(width: headSize, height: headSize)
            HStack(spacing: size * 0.06) {
                eye
                eye
            }
        }
    }

    private var eye: some View {
        let eyeSize: CGFloat = size * 0.15
        let glintSize: CGFloat = size * 0.05
        let glintOffset: CGFloat = size * 0.02
        let glowRadius: CGFloat = size * 0.10

        return Circle()
            .fill(status.glow)
            .frame(width: eyeSize, height: eyeSize)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: glintSize, height: glintSize)
                    .offset(x: -glintOffset, y: -glintOffset)
            }
            .shadow(color: status.glow.opacity(0.9), radius: glowRadius)
    }

    private var plateSymbolColor: Color {
        switch status {
        case .strongConnection, .inQuestion: WallTheme.ink.opacity(0.8)
        default: Color.white.opacity(0.9)
        }
    }

    // MARK: - Legs

    private var legs: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let y: CGFloat = bodyHeight * (-0.12 + CGFloat(index) * 0.22)
                let spread: CGFloat = bodyWidth * (0.42 + CGFloat(index) * 0.05)
                legPair(y: y, spread: spread)
            }
        }
    }

    private func legPair(y: CGFloat, spread: CGFloat) -> some View {
        let legLength: CGFloat = size * 0.22
        let legThickness: CGFloat = max(1, size * 0.045)

        return ZStack {
            Capsule()
                .fill(WallTheme.ink.opacity(0.8))
                .frame(width: legLength, height: legThickness)
                .rotationEffect(.degrees(22))
                .offset(x: -spread, y: y)
            Capsule()
                .fill(WallTheme.ink.opacity(0.8))
                .frame(width: legLength, height: legThickness)
                .rotationEffect(.degrees(-22))
                .offset(x: spread, y: y)
        }
    }
}

/// Torn notch drawn across a tattered wing.
private struct TatteredNotch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.55, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: 0))
        return path
    }
}

/// Angular vein drawn across a jagged wing.
private struct JaggedVein: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.4))
        return path
    }
}

#Preview {
    ZStack {
        WallTheme.bone
        VStack(spacing: 24) {
            HStack(spacing: 18) {
                ForEach(FlyStatus.allCases.prefix(4)) { status in
                    FlyView(status: status, size: 40)
                }
            }
            HStack(spacing: 18) {
                ForEach(FlyStatus.allCases.suffix(4)) { status in
                    FlyView(status: status, size: 40)
                }
            }
        }
    }
    .ignoresSafeArea()
}
