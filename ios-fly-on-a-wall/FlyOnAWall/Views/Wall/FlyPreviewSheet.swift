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

            VStack(spacing: 14) {
                Spacer()

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
                                    .font(WallFont.stamp(9))
                                    .foregroundStyle(WallTheme.inkSoft)
                            }
                            Spacer(minLength: 0)
                        }

                        if let buzz = store.currentBuzz(for: liveFly) {
                            categoryChip(buzz.category)
                            Text(buzz.text)
                                .font(WallFont.marker(17, weight: .medium))
                                .foregroundStyle(WallTheme.ink)
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("😂 \(buzz.reactionCount)    💬 \(buzz.buzzBackCount)    👀 \(buzz.iWasThereCount)")
                                .font(WallFont.stamp(11))
                                .foregroundStyle(WallTheme.inkSoft)
                        }
                    }
                }

                PlateButton(title: "READ THE BUZZ", systemImage: "arrow.turn.down.right") {
                    goTo(.buzz(currentBuzzID))
                }

                PlateButton(title: "VIEW HIVE", systemImage: "hexagon.fill", tint: WallTheme.teal) {
                    goTo(.hive(liveFly.id))
                }

                followButton

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var currentBuzzID: String {
        store.currentBuzz(for: liveFly)?.id ?? ""
    }

    private func categoryChip(_ category: BuzzCategory) -> some View {
        HStack(spacing: 5) {
            Text(category.emoji).font(.system(size: 11))
            Text(category.title)
                .font(WallFont.stamp(9))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(category.tint))
    }

    private var followButton: some View {
        Button {
            Haptics.tap()
            store.toggleFollow(liveFly.id)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: isFollowing ? "checkmark" : "ant.fill")
                    .font(.system(size: 16, weight: .heavy))
                Text(isFollowing ? "FOLLOWING" : "FOLLOW FLY")
                    .font(WallFont.stencil(20))
                    .kerning(1.2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                ZStack {
                    if isFollowing {
                        Capsule()
                            .fill(WallTheme.ink.opacity(0.85))
                            .overlay(Capsule().stroke(WallTheme.teal.opacity(0.9), lineWidth: 1.6))
                    } else {
                        RustPlateBackground(color: WallTheme.teal)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(isFollowing ? "Following \(liveFly.username)" : "Follow \(liveFly.username)")
    }

    private func goTo(_ route: WallRoute) {
        Haptics.tap()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            path.append(route)
        }
    }
}
