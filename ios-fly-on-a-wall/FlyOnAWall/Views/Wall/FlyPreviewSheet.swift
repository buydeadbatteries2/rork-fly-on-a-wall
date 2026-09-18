//
//  FlyPreviewSheet.swift
//  FlyOnAWall
//
//  Tapping a blogger Fly on The Wall pauses it and peels off a taped note:
//  their handle, current status and a preview of their CURRENT BUZZ.
//

import SwiftUI

struct FlyPreviewSheet: View {
    let fly: FlyProfile
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var liveFly: FlyProfile { store.profile(id: fly.id) ?? fly }
    private var isFollowing: Bool { store.isFollowing(fly.id) }

    var body: some View {
        ZStack {
            WallBackdrop(tint: liveFly.currentStatus.tint, tintStrength: 0.12)

            VStack(spacing: 12) {
                // Info + Buzz card scrolls when a long Buzz needs more room;
                // the action area stays pinned and always tappable.
                ScrollView {
                    previewCard
                }
                .scrollBounceBehavior(.basedOnSize)

                // The rusty plate appears ONCE — for the primary action only.
                PlateButton(title: "READ THE BUZZ", systemImage: "arrow.turn.down.right") {
                    goTo(.buzz(currentBuzzID))
                }

                HStack(spacing: 10) {
                    chipButton(title: "VIEW HIVE", systemImage: "hexagon.fill", isFilled: false) {
                        goTo(.hive(liveFly.id))
                    }

                    chipButton(
                        title: isFollowing ? "FOLLOWING" : "FOLLOW FLY",
                        systemImage: isFollowing ? "checkmark" : "ant.fill",
                        isFilled: isFollowing
                    ) {
                        Haptics.tap()
                        store.toggleFollow(liveFly.id)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Header (avatar, handle, status, followers) plus the full current Buzz,
    /// on one taped paper scrap. No line limit — long Buzzes scroll instead of
    /// being clipped or hidden.
    private var previewCard: some View {
        TapedPaper(rotation: -1.4, padding: 18) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 11) {
                    FlyView(status: liveFly.currentStatus, size: 30, wingsBeating: true)
                        .frame(width: 48, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(liveFly.username)
                            .font(WallFont.stencil(19))
                            .foregroundStyle(WallTheme.ink)
                        Text("\(liveFly.currentStatus.title) · \(liveFly.followerDisplay) FOLLOWERS")
                            .font(WallFont.meta(11))
                            .foregroundStyle(WallTheme.ink)
                    }
                    Spacer(minLength: 0)
                }

                if let buzz = store.currentBuzz(for: liveFly) {
                    categoryChip(buzz.category)
                    Text(buzz.text)
                        .font(WallFont.marker(17, weight: .medium))
                        .foregroundStyle(WallTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("😂 \(buzz.reactionCount)    💬 \(buzz.buzzBackCount)    👀 \(buzz.iWasThereCount)")
                        .font(WallFont.meta(12))
                        .foregroundStyle(WallTheme.ink)
                }
            }
        }
    }

    private var currentBuzzID: String {
        store.currentBuzz(for: liveFly)?.id ?? ""
    }

    private func categoryChip(_ category: BuzzCategory) -> some View {
        HStack(spacing: 5) {
            Text(category.emoji).font(.system(size: 11))
            Text(category.title)
                .font(WallFont.stamp(10))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(category.tint))
    }

    /// Compact secondary action — distressed paper chip (or painted capsule
    /// when filled). No plate artwork, so the sheet never stacks heavy metal.
    private func chipButton(
        title: String,
        systemImage: String,
        isFilled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .heavy))
                Text(title)
                    .font(WallFont.stamp(13))
                    .kerning(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isFilled ? .white : WallTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background {
                ZStack {
                    if isFilled {
                        Capsule()
                            .fill(WallTheme.ink.opacity(0.85))
                            .overlay(Capsule().stroke(WallTheme.teal.opacity(0.9), lineWidth: 1.6))
                    } else {
                        Capsule()
                            .fill(WallTheme.paper.opacity(0.95))
                            .overlay(Capsule().stroke(WallTheme.inkSoft.opacity(0.5), lineWidth: 1.2))
                    }
                }
                .allowsHitTesting(false)
            }
            .wallShadow(radius: 5, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }

    private func goTo(_ route: WallRoute) {
        Haptics.tap()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            path.append(route)
        }
    }
}
