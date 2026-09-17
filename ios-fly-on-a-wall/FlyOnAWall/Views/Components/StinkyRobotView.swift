//
//  StinkyRobotView.swift
//  FlyOnAWall
//
//  The mascot. Renders the generated artwork with lightweight overlay "face"
//  effects, head tilt, body shift and celebration bounce. Behaviour values come
//  from RobotDirector; the artwork itself is never redrawn.
//

import SwiftUI

/// Animation states the robot can express; some swap to the swat artwork.
enum RobotState: String, Hashable {
    case idle
    case blink
    case lookingAtFly
    case swat
    case surprised
    case laughing
    case annoyed

    /// Which artwork the state renders with.
    var usesSwatArt: Bool {
        switch self {
        case .swat, .surprised: true
        default: false
        }
    }
}

/// The beat-up mascot with a stink cloud, drawn from generated artwork with a
/// vector fallback so the scene is never empty.
struct StinkyRobotView: View {
    var director: RobotDirector
    var height: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe: Bool = false
    @State private var swatSwing: Bool = false
    @State private var squash: Bool = false

    private var assetName: String { director.state.usesSwatArt ? WallAsset.robotSwat : WallAsset.robotIdle }

    var body: some View {
        ZStack(alignment: .bottom) {
            StinkCloud(height: height, boost: director.stinkBoost)
                .offset(x: height * 0.28, y: -height * 0.34)

            Group {
                if let image = UIImage(named: assetName) {
                    robotImage(image)
                } else {
                    FallbackRobot(isSwatting: director.state.usesSwatArt)
                        .frame(height: height)
                }
            }
            .frame(height: height)
            .rotationEffect(.degrees(swatSwing ? -7 : 0), anchor: .bottom)
            .rotationEffect(.degrees(director.headTilt), anchor: .bottom)
            .offset(director.bodyShift)
            .scaleEffect(x: 1, y: squash ? 0.968 : breathe ? 1.012 : 0.988, anchor: .bottom)
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
        }
        .frame(height: height * 1.18, alignment: .bottom)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onChange(of: director.state) { _, newValue in
            guard !reduceMotion else { return }
            if newValue == .swat {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.4)) { swatSwing = true }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.22)) { swatSwing = false }
            }
        }
        .onChange(of: director.isCelebrating) { _, isCelebrating in
            guard !reduceMotion else { return }
            if isCelebrating {
                withAnimation(.easeInOut(duration: 0.26).repeatForever(autoreverses: true)) { squash = true }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { squash = false }
            }
        }
    }

    /// Artwork plus the face overlay layer, locked to the image's real aspect.
    private func robotImage(_ image: UIImage) -> some View {
        let aspect = image.size.width / max(1, image.size.height)
        let width = height * aspect
        return ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            faceOverlays(width: width, height: height)
        }
        .frame(width: width, height: height)
    }

    // MARK: - Face overlays

    /// Eye anchors measured from the artwork: pupil, lid and effect positions
    /// are expressed as fractions of the rendered image so they stay put at any
    /// robot size. (The swat pose holds its arm up, so its head sits lower.)
    private struct FaceAnchor {
        let leftEye: CGPoint
        let rightEye: CGPoint
        let eyeRadius: CGFloat

        static let idle = FaceAnchor(
            leftEye: CGPoint(x: 0.393, y: 0.198),
            rightEye: CGPoint(x: 0.605, y: 0.181),
            eyeRadius: 0.055
        )
        static let swat = FaceAnchor(
            leftEye: CGPoint(x: 0.494, y: 0.337),
            rightEye: CGPoint(x: 0.592, y: 0.392),
            eyeRadius: 0.048
        )
    }

    @ViewBuilder
    private func faceOverlays(width w: CGFloat, height h: CGFloat) -> some View {
        let face: FaceAnchor = director.state.usesSwatArt ? .swat : .idle
        let eyeRadius = face.eyeRadius * w
        let left = CGPoint(x: face.leftEye.x * w, y: face.leftEye.y * h)
        let right = CGPoint(x: face.rightEye.x * w, y: face.rightEye.y * h)
        let lookOffset = CGSize(
            width: director.look.width * eyeRadius * 0.5,
            height: director.look.height * eyeRadius * 0.4
        )

        ZStack {
            switch director.expression {
            case .neutral, .annoyed, .suspicious, .skeptical, .surprised:
                pupil(at: left, radius: eyeRadius, offset: lookOffset, dilated: director.expression == .surprised)
                pupil(at: right, radius: eyeRadius, offset: lookOffset, dilated: director.expression == .surprised)

                if director.expression == .surprised {
                    ring(at: left, radius: eyeRadius)
                    ring(at: right, radius: eyeRadius)
                }
                if director.expression == .annoyed {
                    upperLid(at: left, radius: eyeRadius, tilt: 8)
                    upperLid(at: right, radius: eyeRadius, tilt: -8)
                }
                if director.expression == .suspicious {
                    upperLid(at: left, radius: eyeRadius, tilt: 4)
                    upperLid(at: right, radius: eyeRadius, tilt: -4)
                }
                if director.expression == .skeptical {
                    fullLid(at: right, radius: eyeRadius, tilt: -4)
                }

            case .blink:
                fullLid(at: left, radius: eyeRadius, tilt: 0)
                fullLid(at: right, radius: eyeRadius, tilt: 0)

            case .laughing:
                happyArc(at: left, radius: eyeRadius)
                happyArc(at: right, radius: eyeRadius)
            }

            if director.expression == .suspicious && !reduceMotion {
                sweatDrop(near: CGPoint(x: w * 0.70, y: h * 0.12), radius: eyeRadius)
            }
        }
        .allowsHitTesting(false)
    }

    private func pupil(at center: CGPoint, radius: CGFloat, offset: CGSize, dilated: Bool) -> some View {
        Circle()
            .fill(WallTheme.ink.opacity(0.9))
            .frame(width: radius * (dilated ? 1.1 : 0.7), height: radius * (dilated ? 1.1 : 0.7))
            .offset(x: center.x - radius + offset.width, y: center.y - radius + offset.height)
            .animation(.easeInOut(duration: 0.25), value: offset)
    }

    private func upperLid(at center: CGPoint, radius: CGFloat, tilt: Double) -> some View {
        Capsule()
            .fill(WallTheme.ink.opacity(0.85))
            .frame(width: radius * 2.3, height: radius * 1.25)
            .rotationEffect(.degrees(tilt))
            .offset(x: center.x - radius * 1.15, y: center.y - radius * 1.5)
    }

    private func fullLid(at center: CGPoint, radius: CGFloat, tilt: Double) -> some View {
        Capsule()
            .fill(WallTheme.ink.opacity(0.85))
            .frame(width: radius * 2.3, height: radius * 0.55)
            .rotationEffect(.degrees(tilt))
            .offset(x: center.x - radius * 1.15, y: center.y - radius * 0.27)
    }

    private func ring(at center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .stroke(WallTheme.bone.opacity(0.85), lineWidth: max(1.5, radius * 0.25))
            .frame(width: radius * 2.6, height: radius * 2.6)
            .offset(x: center.x - radius * 1.3, y: center.y - radius * 1.3)
    }

    private func happyArc(at center: CGPoint, radius: CGFloat) -> some View {
        let arcWidth: CGFloat = radius * 2.0
        let arcHeight: CGFloat = radius * 1.1
        let lineWidth: CGFloat = max(2, radius * 0.35)
        let arc = HappyEyeArc()
            .stroke(WallTheme.ink.opacity(0.9), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        return arc
            .frame(width: arcWidth, height: arcHeight)
            .offset(x: center.x - arcWidth / 2, y: center.y - arcHeight * 0.55)
    }

    private func sweatDrop(near point: CGPoint, radius: CGFloat) -> some View {
        Ellipse()
            .fill(WallTheme.teal.opacity(0.75))
            .frame(width: radius * 0.6, height: radius * 0.95)
            .offset(x: point.x, y: point.y)
    }
}

/// Happy closed eye: an upside-down arc.
private struct HappyEyeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: min(rect.width / 2, rect.height),
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

/// Drifting stink puffs; `boost` gives an annoyed huff extra presence.
private struct StinkCloud: View {
    let height: CGFloat
    var boost: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rise: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let scale = 1.0 - Double(index) * 0.22
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.65, green: 0.72, blue: 0.29).opacity(0.34),
                                Color(red: 0.55, green: 0.66, blue: 0.24).opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: height * 0.16 * scale
                        )
                    )
                    .frame(width: height * 0.32 * scale, height: height * 0.32 * scale)
                    .offset(
                        x: CGFloat(index % 2 == 0 ? -8 : 10),
                        y: rise ? -CGFloat(index) * height * 0.13 - height * 0.08 : -CGFloat(index) * height * 0.06
                    )
                    .opacity(rise ? 0.25 : 0.75)
            }
        }
        .scaleEffect(boost ? 1.3 : 1.0)
        .opacity(boost ? 1.0 : 0.85)
        .animation(.easeInOut(duration: 0.6), value: boost)
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                rise = true
            }
        }
    }
}

/// Simple vector robot used only if the generated artwork is unavailable.
private struct FallbackRobot: View {
    let isSwatting: Bool

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: h * 0.08)
                    .fill(LinearGradient(colors: [WallTheme.warmGray, WallTheme.rust.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: h * 0.46, height: h * 0.46)
                    .offset(y: h * 0.12)
                Circle()
                    .fill(WallTheme.warmGray)
                    .frame(width: h * 0.34, height: h * 0.34)
                    .overlay {
                        HStack(spacing: h * 0.03) {
                            Circle().fill(.white).frame(width: h * 0.1, height: h * 0.1)
                                .overlay(Circle().fill(WallTheme.ink).frame(width: h * 0.045, height: h * 0.045))
                            Circle().fill(.white).frame(width: h * 0.08, height: h * 0.08)
                                .overlay(Circle().fill(WallTheme.ink).frame(width: h * 0.035, height: h * 0.035))
                        }
                    }
                    .offset(y: -h * 0.22)
                Capsule()
                    .fill(WallTheme.ink.opacity(0.7))
                    .frame(width: h * 0.06, height: h * 0.3)
                    .rotationEffect(.degrees(isSwatting ? -50 : -12), anchor: .bottom)
                    .offset(x: -h * 0.26, y: isSwatting ? -h * 0.05 : h * 0.1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .aspectRatio(0.8, contentMode: .fit)
    }
}
