//
//  ConnectedFliesSheet.swift
//  FlyOnAWall
//
//  Flies that touch this fly.
//

import SwiftUI

struct ConnectedFliesSheet: View {
    let story: StoryFly
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var connected: [StoryFly] { store.connectedFlies(to: story) }

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.teal, tintStrength: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        StencilTitle(text: "CONNECTED FLIES", size: 28)
                        Text(connected.isEmpty
                             ? "Nothing overlaps this one yet."
                             : "\(connected.count) other flies circle the same night.")
                            .font(WallFont.marker(14))
                            .foregroundStyle(WallTheme.ink.opacity(0.85))
                    }
                    .padding(.top, 10)

                    ForEach(connected) { fly in
                        Button {
                            Haptics.tap()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                path.append(WallRoute.story(fly.id))
                            }
                        } label: {
                            TapedPaper(rotation: Double(abs(fly.id.hashValue % 3)) - 1.0, padding: 14) {
                                HStack(spacing: 12) {
                                    FlyView(category: fly.category, size: 26, wingsBeating: false)
                                        .frame(width: 44, height: 38)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(fly.handle)
                                            .font(WallFont.stamp(12))
                                            .foregroundStyle(WallTheme.rust)
                                        Text(fly.text)
                                            .font(WallFont.marker(14, weight: .regular))
                                            .foregroundStyle(WallTheme.ink)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.98))
                    }

                    Color.clear.frame(height: 70)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) {
                PlateButton(title: "CLOSE", systemImage: "xmark") {
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
}
