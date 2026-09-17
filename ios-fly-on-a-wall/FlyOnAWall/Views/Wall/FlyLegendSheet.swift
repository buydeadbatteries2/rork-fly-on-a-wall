//
//  FlyLegendSheet.swift
//  FlyOnAWall
//
//  KNOW YOUR FLIES — the legend, styled as a clipboard bolted to the wall.
//

import SwiftUI

struct FlyLegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.warmGray, tintStrength: 0.14)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        StencilTitle(text: "KNOW YOUR FLIES", size: 30)
                        Text("Colour tells you what. Shape and speed tell you why.")
                            .font(WallFont.marker(13, weight: .medium))
                            .foregroundStyle(WallTheme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 6)

                    VStack(spacing: 10) {
                        ForEach(FlyCategory.allCases) { category in
                            legendRow(category)
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WallTheme.paper.opacity(0.94))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(WallTheme.inkSoft.opacity(0.4), lineWidth: 1.5))
                            .wallShadow(radius: 12, y: 6)
                    }
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(WallTheme.warmGray)
                            .frame(width: 88, height: 14)
                            .overlay(Capsule().stroke(WallTheme.ink.opacity(0.5), lineWidth: 1))
                            .offset(y: -7)
                    }

                    Text("Every fly is somebody's real, terrible evening.")
                        .font(WallFont.marker(13))
                        .foregroundStyle(WallTheme.inkSoft)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                PlateButton(title: "GOT IT", systemImage: "checkmark") {
                    Haptics.tap()
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }

    private func legendRow(_ category: FlyCategory) -> some View {
        HStack(spacing: 12) {
            FlyView(category: category, size: 30, wingsBeating: false)
                .frame(width: 50, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(WallFont.stencil(17))
                    .foregroundStyle(WallTheme.ink)
                Text(category.blurb)
                    .font(WallFont.marker(12, weight: .regular))
                    .foregroundStyle(WallTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Text(category.motionNote)
                .font(WallFont.stamp(10))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(category == .strongConnection ? WallTheme.inkSoft : category.tint.opacity(0.9))
                )
                .frame(maxWidth: 96, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FlyLegendSheet()
}
