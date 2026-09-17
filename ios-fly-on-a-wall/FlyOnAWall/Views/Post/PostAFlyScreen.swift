//
//  PostAFlyScreen.swift
//  FlyOnAWall
//
//  POST A FLY — never "create post".
//

import SwiftUI

struct PostAFlyScreen: View {
    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isWriting: Bool
    @State private var text: String = ""
    @State private var didPost: Bool = false
    @State private var launchFly: Bool = false

    private let limit: Int = 500
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canPost: Bool { trimmed.count >= 4 }

    var body: some View {
        ZStack {
            WallBackdrop()

            if didPost {
                confirmation
            } else {
                composer
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    StencilTitle(text: "POST A FLY", size: 40)
                    Text("Anonymous, always.")
                        .font(WallFont.marker(15))
                        .foregroundStyle(WallTheme.ink.opacity(0.8))
                        .shadow(color: WallTheme.bone.opacity(0.5), radius: 0, x: 1, y: 1)
                }
                .padding(.top, 6)

                TapedPaper(rotation: -1.4, padding: 16) {
                    Text("What did you see, hear, do, or need to confess?")
                        .font(WallFont.marker(18))
                        .foregroundStyle(WallTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                editor

                Color.clear.frame(height: WallMetrics.tabBarClearance + 70)
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                PlateButton(title: "POST MY FLY", systemImage: "ant.fill") {
                    post()
                }
                .opacity(canPost ? 1 : 0.5)
                .disabled(!canPost)

                Text("Anonymous flies buzz brighter together.")
                    .font(WallFont.stamp(10))
                    .foregroundStyle(WallTheme.paper.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, WallMetrics.tabBarClearance - 18)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") { isWriting = false }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(WallTheme.paper.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.4))
                .wallShadow(radius: 10, y: 6)

            if text.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share your story...")
                    Text("(anonymous, always)")
                        .font(WallFont.marker(15, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft.opacity(0.55))
                }
                .font(WallFont.marker(17, weight: .regular))
                .foregroundStyle(WallTheme.inkSoft.opacity(0.6))
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .focused($isWriting)
                .font(WallFont.marker(17, weight: .regular))
                .foregroundStyle(WallTheme.ink)
                .lineSpacing(4)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .onChange(of: text) { _, newValue in
                    if newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Text("FLIES\nTELL ALL")
                        .font(WallFont.stamp(10))
                        .foregroundStyle(WallTheme.inkSoft.opacity(0.5))
                        .multilineTextAlignment(.trailing)
                        .rotationEffect(.degrees(4))
                        .padding(.trailing, 12)
                        .padding(.top, 10)
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("\(text.count) / \(limit)")
                        .font(WallFont.stamp(12))
                        .foregroundStyle(text.count > limit - 40 ? WallTheme.rust : WallTheme.inkSoft)
                        .padding(.trailing, 14)
                        .padding(.bottom, 10)
                }
            }
            .allowsHitTesting(false)
        }
        .frame(height: 280)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Confirmation

    private var confirmation: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [WallTheme.rust.opacity(0.4), .clear], center: .center, startRadius: 4, endRadius: 110))
                    .frame(width: 220, height: 220)
                FlyView(category: .new, size: 70)
                    .offset(x: launchFly ? 34 : -26, y: launchFly ? -46 : 18)
                    .rotationEffect(.degrees(launchFly ? 14 : -8))
            }
            .frame(height: 200)

            StencilTitle(text: "YOUR FLY IS BUZZING", size: 30, color: WallTheme.paper)
                .multilineTextAlignment(.center)
            Text("🪰 It just landed on The Wall with everybody else's bad decisions.")
                .font(WallFont.marker(15))
                .foregroundStyle(WallTheme.paper.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            PlateButton(title: "POST ANOTHER", systemImage: "plus") {
                Haptics.tap()
                withAnimation(.easeOut(duration: 0.2)) {
                    didPost = false
                    launchFly = false
                    text = ""
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, WallMetrics.tabBarClearance)
        .transition(.scale(scale: 0.88).combined(with: .opacity))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                launchFly = true
            }
        }
    }

    private func post() {
        guard canPost else { return }
        isWriting = false
        store.postFly(text: trimmed)
        Haptics.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            didPost = true
        }
    }
}
