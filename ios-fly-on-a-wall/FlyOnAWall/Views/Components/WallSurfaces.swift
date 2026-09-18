//
//  WallSurfaces.swift
//  FlyOnAWall
//
//  Shared surface language: wall backdrop, taped paper scraps, action
//  surfaces, stencil titles.
//

import SwiftUI

/// Full-bleed sunbleached wall backdrop. Uses the generated texture when
/// available and falls back to a painted gradient so the app never looks empty.
struct WallBackdrop: View {
    var tint: Color? = nil
    var tintStrength: Double = 0.18
    /// Environment dimming applied ABOVE the artwork and BELOW all foreground
    /// UI. Standard screens use `standardDim`; modal presentations pass
    /// `modalDim` so the environment recedes further behind the popup.
    var dim: Double = WallBackdrop.standardDim

    /// Standard screen dimming — grunge stays visible, foreground pops.
    static let standardDim: Double = 0.18
    /// Dimming behind an active modal/sheet (stronger, still not dark mode).
    static let modalDim: Double = 0.40

    /// Manual Night Mode, persisted locally. The same wall, after dark.
    @AppStorage("flyNightMode") private var nightMode = false

    private enum Night {
        /// Cool moonlit wash composited over the UNMODIFIED artwork.
        static let wash = Color(red: 0.02, green: 0.06, blue: 0.14)
        static let washOpacity = 0.48
    }

    /// Night's cool wash already darkens the wall, so the plain black dim is
    /// softened — DAY/NIGHT × normal/modal layers never stack into black.
    private var effectiveDim: Double {
        guard nightMode else { return dim }
        return dim >= Self.modalDim ? 0.20 : 0.06
    }

    var body: some View {
        ZStack {
            if let image = UIImage(named: WallAsset.wall) {
                Color(WallTheme.warmGray)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipped()
            } else {
                ProceduralWall()
            }

            if let tint {
                tint.opacity(tintStrength).blendMode(.multiply)
            }

            // Subtle dim between the environment and every foreground layer.
            // Pure color layer — negligible cost, never touches content.
            Color.black.opacity(effectiveDim)
                .allowsHitTesting(false)

            // Night Mode: cool wash over the same artwork — nighttime at The
            // Wall, not dark mode. Foreground content is unaffected.
            if nightMode {
                Night.wash.opacity(Night.washOpacity)
                    .allowsHitTesting(false)
            }

            // Vignette keeps the chrome readable over a bright texture.
            LinearGradient(
                colors: [.black.opacity(0.22), .clear, .clear, .black.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

/// Painted concrete fallback drawn entirely in SwiftUI.
private struct ProceduralWall: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WallTheme.bone,
                    WallTheme.bone.opacity(0.92),
                    WallTheme.warmGray
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                var rng = WallRandom(seed: 99)
                for _ in 0..<26 {
                    let x = CGFloat(rng.next(in: 0...Double(size.width)))
                    let y = CGFloat(rng.next(in: 0...Double(size.height)))
                    let w = CGFloat(rng.next(in: 30...170))
                    let h = CGFloat(rng.next(in: 20...110))
                    let opacity = rng.next(in: 0.03...0.11)
                    context.fill(
                        Ellipse().path(in: CGRect(x: x, y: y, width: w, height: h)),
                        with: .color(WallTheme.inkSoft.opacity(opacity))
                    )
                }
                for _ in 0..<12 {
                    var path = Path()
                    let x = CGFloat(rng.next(in: 0...Double(size.width)))
                    let y = CGFloat(rng.next(in: 0...Double(size.height)))
                    path.move(to: CGPoint(x: x, y: y))
                    var current = CGPoint(x: x, y: y)
                    for _ in 0..<5 {
                        current = CGPoint(
                            x: current.x + CGFloat(rng.next(in: -26...26)),
                            y: current.y + CGFloat(rng.next(in: 16...58))
                        )
                        path.addLine(to: current)
                    }
                    context.stroke(path, with: .color(WallTheme.ink.opacity(0.14)), lineWidth: 1.4)
                }
                for _ in 0..<7 {
                    let x = CGFloat(rng.next(in: 0...Double(size.width)))
                    let w = CGFloat(rng.next(in: 6...18))
                    let h = CGFloat(rng.next(in: 60...260))
                    context.fill(
                        Capsule().path(in: CGRect(x: x, y: 0, width: w, height: h)),
                        with: .color(WallTheme.rust.opacity(rng.next(in: 0.05...0.14)))
                    )
                }
            }
        }
    }
}

/// A piece of aged paper taped to the wall. Content is laid out on top.
/// A translucent cream wash lifts stains and shadows in the texture so dark
/// text stays readable, while torn edges and grain stay visible around it.
struct TapedPaper<Content: View>: View {
    var rotation: Double = -1.2
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    if let image = UIImage(named: WallAsset.paper) {
                        Image(uiImage: image)
                            .resizable(capInsets: EdgeInsets(top: 90, leading: 90, bottom: 90, trailing: 90), resizingMode: .stretch)
                        // Cream wash for text contrast (readability pass).
                        Rectangle()
                            .fill(WallTheme.paper.opacity(0.42))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(WallTheme.paper)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(WallTheme.inkSoft.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) { tape.rotationEffect(.degrees(-16)).offset(x: -6, y: -10) }
            .overlay(alignment: .topTrailing) { tape.rotationEffect(.degrees(12)).offset(x: 8, y: -12) }
            .rotationEffect(.degrees(rotation))
            .wallShadow()
    }

    private var tape: some View {
        Rectangle()
            .fill(Color(red: 0.87, green: 0.82, blue: 0.68).opacity(0.72))
            .frame(width: 56, height: 20)
            .overlay(Rectangle().stroke(.white.opacity(0.25), lineWidth: 0.5))
    }
}

/// A dark painted patch on the wall carrying section headers and informational
/// copy: the wall gives atmosphere, information gets a surface. Reads as a
/// painted/stenciled wall patch, not a white card.
struct WallPatch: View {
    let title: String
    var subline: String? = nil
    /// Larger stencil size for screen titles; smaller for section headers.
    var titleSize: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(WallFont.stencil(titleSize))
                .kerning(1.2)
                .foregroundStyle(WallTheme.paper)
            if let subline {
                Text(subline)
                    .font(WallFont.meta(13))
                    .foregroundStyle(WallTheme.paper.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(WallTheme.ink.opacity(0.60))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(Color(red: 0.87, green: 0.82, blue: 0.68).opacity(0.6))
                .frame(width: 44, height: 14)
                .rotationEffect(.degrees(-14))
                .offset(x: -5, y: -8)
                .allowsHitTesting(false)
        }
        .rotationEffect(.degrees(-0.5))
        .wallShadow(radius: 7, y: 4)
        .accessibilityElement(children: .combine)
    }
}

/// One-line version of the painted patch for small labels like "SAY YOUR PIECE".
struct PatchedLabel: View {
    let text: String
    var size: CGFloat = 15

    var body: some View {
        Text(text)
            .font(WallFont.stencil(size))
            .kerning(1.0)
            .foregroundStyle(WallTheme.paper)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(WallTheme.ink.opacity(0.60))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.12), lineWidth: 1))
            }
            .wallShadow(radius: 5, y: 3)
    }
}

/// Worn spray-stencil title, the app's headline voice.
struct StencilTitle: View {
    let text: String
    var size: CGFloat = 40
    var color: Color = WallTheme.ink

    var body: some View {
        Text(text)
            .font(WallFont.stencil(size))
            .kerning(1.5)
            .foregroundStyle(color)
            .shadow(color: WallTheme.bone.opacity(0.5), radius: 0, x: 1.5, y: 1.5)
            .shadow(color: .black.opacity(0.28), radius: 5, x: 0, y: 3)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Big primary action — a distressed dark surface with a thin industrial
/// border and the tint as the accent edge. No plate artwork anywhere in the
/// app; the rusty nameplate image has zero runtime references.
struct PlateButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = WallTheme.rust
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(WallFont.stencil(23))
                    .kerning(1.2)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .heavy))
                }
            }
            .foregroundStyle(WallTheme.paper)
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [WallTheme.ink.opacity(0.94), WallTheme.ink.opacity(0.80)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [tint.opacity(0.95), .white.opacity(0.20), tint.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .leading) { bolt.padding(.leading, 14) }
            .overlay(alignment: .trailing) { bolt.padding(.trailing, 14) }
            .wallShadow(radius: 6, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }

    private var bolt: some View {
        Circle()
            .fill(
                RadialGradient(colors: [WallTheme.warmGray, WallTheme.ink], center: .topLeading, startRadius: 0, endRadius: 8)
            )
            .frame(width: 10, height: 10)
            .allowsHitTesting(false)
    }
}

/// Squishy press feedback used by every custom control.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
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
