//
//  PostABuzzScreen.swift
//  FlyOnAWall
//
//  POST A BUZZ — the composer. You are the Fly; this is your Buzz.
//  One primary category, up to three tags, session-only posting.
//

import SwiftUI

struct PostABuzzScreen: View {
    @Environment(WallStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isWriting: Bool
    @State private var text: String = ""
    @State private var category: BuzzCategory?
    @State private var tags: Set<String> = []
    @State private var didPost: Bool = false
    @State private var launchFly: Bool = false

    private let limit: Int = 500
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canPost: Bool { trimmed.count >= 4 && category != nil }

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
                    StencilTitle(text: "POST A BUZZ", size: 40)
                    Text("You're the Fly. This is your Buzz.")
                        .font(WallFont.meta(13))
                        .foregroundStyle(WallTheme.ink)
                        .shadow(color: WallTheme.bone.opacity(0.6), radius: 0, x: 1, y: 1)
                }
                .padding(.top, 6)

                TapedPaper(rotation: -1.4, padding: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WHAT'S BUZZING?")
                            .font(WallFont.stencil(20))
                            .foregroundStyle(WallTheme.ink)
                        Text("What did you see, hear, do, or need to get off your chest?")
                            .font(WallFont.meta(14))
                            .foregroundStyle(WallTheme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                editor

                categoryPicker

                if let selected = category {
                    tagPicker(selected)
                }

                Color.clear.frame(height: WallMetrics.tabBarClearance + 70)
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                PlateButton(title: "POST MY BUZZ", systemImage: "ant.fill") {
                    post()
                }
                .opacity(canPost ? 1 : 0.5)
                .disabled(!canPost)

                Text("Your Buzz flies under your handle. That's the deal.")
                    .font(WallFont.meta(12))
                    .foregroundStyle(WallTheme.paper.opacity(0.95))
                    .shadow(color: .black.opacity(0.6), radius: 3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, WallMetrics.tabBarClearance - 18)
            .background {
                // Painted scrim so the CTA never fights the robot/artwork.
                LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
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
                    Text("Spill it...")
                    Text("(the wall takes secrets well)")
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
        .frame(height: 220)
        .accessibilityElement(children: .contain)
    }

    /// ONE primary category — single select, required.
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            PatchedLabel(text: "PICK ONE CATEGORY", size: 16)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 8)], spacing: 8) {
                ForEach(BuzzCategory.allCases) { option in
                    categoryChip(option)
                }
            }
        }
    }

    private func categoryChip(_ option: BuzzCategory) -> some View {
        let isActive = category == option
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                category = isActive ? nil : option
                tags.removeAll()
            }
        } label: {
            HStack(spacing: 6) {
                Text(option.emoji).font(.system(size: 13))
                Text(option.title)
                    .font(WallFont.stamp(11))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                }
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? option.tint : WallTheme.paper.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(isActive ? WallTheme.ink.opacity(0.55) : WallTheme.inkSoft.opacity(0.5), lineWidth: isActive ? 1.6 : 1.3)
                    )
            )
            .wallShadow(radius: 4, y: 2)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.95))
        .accessibilityLabel("Category \(option.title)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    /// Up to THREE tags, suggested from the chosen category.
    private func tagPicker(_ selected: BuzzCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                PatchedLabel(text: "TAGS", size: 16)
                Text("(UP TO 3)")
                    .font(WallFont.meta(12))
                    .foregroundStyle(WallTheme.paper)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }

            FlowTags(tags: selected.suggestedTags, selected: tags) { tag in
                toggleTag(tag)
            }
        }
    }

    private func toggleTag(_ tag: String) {
        Haptics.tap()
        if tags.contains(tag) {
            tags.remove(tag)
        } else if tags.count < 3 {
            tags.insert(tag)
        }
    }

    // MARK: - Confirmation

    private var confirmation: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [WallTheme.rust.opacity(0.4), .clear], center: .center, startRadius: 4, endRadius: 110))
                    .frame(width: 220, height: 220)
                FlyView(status: .new, size: 70)
                    .offset(x: launchFly ? 34 : -26, y: launchFly ? -46 : 18)
                    .rotationEffect(.degrees(launchFly ? 14 : -8))
            }
            .frame(height: 200)

            StencilTitle(text: "YOUR BUZZ IS ON\nTHE WALL", size: 30, color: WallTheme.paper)
                .multilineTextAlignment(.center)
            Text("🪰 It just landed next to everybody else's bad decisions.")
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
                    category = nil
                    tags.removeAll()
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
        guard canPost, let category else { return }
        isWriting = false
        store.postBuzz(text: trimmed, category: category, tags: Array(tags).sorted())
        Haptics.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            didPost = true
        }
    }
}

/// Simple wrapping layout for tag chips (a stacked LazyVGrid would force
/// uniform widths; this keeps them hugging their content).
private struct FlowTags: View {
    let tags: [String]
    let selected: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                tagChip(tag)
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        let isActive = selected.contains(tag)
        return Button {
            onToggle(tag)
        } label: {
            Text(tag)
                .font(WallFont.stamp(12))
                .foregroundStyle(isActive ? .white : WallTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isActive ? WallTheme.teal : WallTheme.paper.opacity(0.95))
                        .overlay(Capsule().stroke(WallTheme.inkSoft.opacity(isActive ? 0.8 : 0.5), lineWidth: 1.2))
                )
                .wallShadow(radius: 4, y: 2)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
        .accessibilityLabel("Tag \(tag)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
