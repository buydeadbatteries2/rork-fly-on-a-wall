//
//  ConnectionSheets.swift
//  FlyOnAWall
//
//  WHY DO THESE FLIES CONNECT? — mock clues behind one connection line —
//  plus the fly inspector used when tapping a related fly on the board.
//  All language is story-to-story. Never identification.
//

import SwiftUI

struct ConnectionClueSheet: View {
    let link: FlyConnection
    let focusStoryID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var otherID: String { link.other(end: focusStoryID) }
    private var other: StoryFly? { store.story(id: otherID) }

    var body: some View {
        ZStack {
            WallBackdrop(tint: FlyCategory.connected.tint, tintStrength: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "WHY DO THESE\nFLIES CONNECT?", size: 26)
                        Text("Mock clues from the overlapping details.")
                            .font(WallFont.marker(13, weight: .regular))
                            .foregroundStyle(WallTheme.ink.opacity(0.8))
                    }
                    .padding(.top, 10)

                    flyCard(title: "THIS FLY", id: focusStoryID)
                    flyCard(title: "THAT FLY", id: otherID)

                    clueList

                    strengthBlock

                    PlateButton(title: "VIEW OTHER FLY", systemImage: "arrow.turn.down.right") {
                        Haptics.tap()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            path.append(WallRoute.story(otherID))
                        }
                    }
                    .disabled(other == nil)

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                PlateButton(title: "CLOSE", systemImage: "xmark", tint: WallTheme.inkSoft) {
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

    private func flyCard(title: String, id: String) -> some View {
        Group {
            if let fly = store.story(id: id) {
                TapedPaper(rotation: title == "THIS FLY" ? -1.2 : 1.1, padding: 12) {
                    HStack(spacing: 11) {
                        FlyView(category: fly.category, size: 24, wingsBeating: false)
                            .frame(width: 40, height: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(WallFont.stamp(9))
                                .foregroundStyle(WallTheme.rust)
                            Text(fly.handle)
                                .font(WallFont.stamp(12))
                                .foregroundStyle(WallTheme.ink)
                            Text(fly.text)
                                .font(WallFont.marker(13, weight: .regular))
                                .foregroundStyle(WallTheme.inkSoft)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var clueList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(link.overlappingClues) { clue in
                HStack(spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WallTheme.teal)
                    Image(systemName: clue.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WallTheme.inkSoft)
                    Text(clue.rawValue)
                        .font(WallFont.marker(15, weight: .medium))
                        .foregroundStyle(WallTheme.ink)
                    Spacer(minLength: 0)
                }
            }
            ForEach(link.conflictingClues, id: \.self) { conflict in
                HStack(spacing: 9) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WallTheme.rust)
                    Text(conflict)
                        .font(WallFont.marker(15, weight: .medium))
                        .foregroundStyle(WallTheme.ink)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.paper.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(WallTheme.inkSoft.opacity(0.4), lineWidth: 1.2))
                .wallShadow(radius: 8, y: 4)
        }
    }

    private var strengthBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CONNECTION STRENGTH")
                .font(WallFont.stamp(10))
                .foregroundStyle(WallTheme.inkSoft)
            Text(link.strength.title)
                .font(WallFont.stencil(24))
                .foregroundStyle(link.strength.lineColor)
            Text(link.strength.blurb)
                .font(WallFont.marker(14, weight: .regular))
                .foregroundStyle(WallTheme.ink)
            if let safety = link.strength.safetyLine {
                Text(safety)
                    .font(WallFont.marker(12, weight: .regular))
                    .foregroundStyle(WallTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(link.strength.lineColor.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(link.strength.lineColor.opacity(0.55), lineWidth: 1.4))
        }
    }
}

/// Quick look at a related fly from the board before following it.
struct FlyInspectorSheet: View {
    let story: StoryFly
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WallBackdrop(tint: story.category.tint, tintStrength: 0.12)

            VStack(spacing: 16) {
                Spacer()

                TapedPaper(rotation: -1.3, padding: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 11) {
                            FlyView(category: story.category, size: 28, wingsBeating: true)
                                .frame(width: 46, height: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(story.handle) · Anonymous")
                                    .font(WallFont.stamp(12))
                                    .foregroundStyle(WallTheme.rust)
                                Text("Posted \(story.postedAgo)")
                                    .font(WallFont.marker(12, weight: .regular))
                                    .foregroundStyle(WallTheme.inkSoft)
                            }
                            Spacer(minLength: 0)
                        }
                        Text(story.text)
                            .font(WallFont.marker(17, weight: .medium))
                            .foregroundStyle(WallTheme.ink)
                            .lineLimit(5)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                let linkCount = store.connections(touching: story.id).count
                if linkCount > 0 {
                    Text("🟣 \(linkCount) CONNECTED FLIES")
                        .font(WallFont.stamp(12))
                        .foregroundStyle(FlyCategory.connected.tint)
                }

                PlateButton(title: "VIEW STORY", systemImage: "arrow.turn.down.right") {
                    Haptics.tap()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        path.append(WallRoute.story(story.id))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
