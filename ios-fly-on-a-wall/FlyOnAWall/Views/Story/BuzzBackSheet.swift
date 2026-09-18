//
//  BuzzBackSheet.swift
//  FlyOnAWall
//
//  BUZZ BACK — the normal reply. Deliberately different from I WAS THERE:
//  Buzz Back is discussion; I WAS THERE claims direct involvement.
//

import SwiftUI

struct BuzzBackSheet: View {
    let buzz: Buzz

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWriting: Bool
    @State private var text: String = ""
    @State private var didSubmit: Bool = false

    private let limit: Int = 240

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.teal, tintStrength: 0.14)

            if didSubmit {
                confirmation
            } else {
                form
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("BUZZ BACK")
                            .font(WallFont.stencil(36))
                            .foregroundStyle(WallTheme.ink)
                        Text("💬").font(.system(size: 28))
                    }
                    Text("Talk back. This is the discussion — not a witness claim.")
                        .font(WallFont.marker(15))
                        .foregroundStyle(WallTheme.ink.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)

                TapedPaper(rotation: -0.8, padding: 14) {
                    HStack(spacing: 8) {
                        Text(buzz.authorUsername)
                            .font(WallFont.stamp(10))
                            .foregroundStyle(WallTheme.rust)
                        Text(buzz.text)
                            .font(WallFont.marker(13, weight: .regular))
                            .foregroundStyle(WallTheme.inkSoft)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    PatchedLabel(text: "SAY YOUR PIECE", size: 15)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(WallTheme.paper.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.2))

                        if text.isEmpty {
                            Text("Add to the conversation...")
                                .font(WallFont.marker(15, weight: .regular))
                                .foregroundStyle(WallTheme.inkSoft.opacity(0.6))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $text)
                            .focused($isWriting)
                            .font(WallFont.marker(15, weight: .regular))
                            .foregroundStyle(WallTheme.ink)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .onChange(of: text) { _, newValue in
                                if newValue.count > limit {
                                    text = String(newValue.prefix(limit))
                                }
                            }
                    }
                    .frame(height: 140)
                    .wallShadow(radius: 8, y: 5)

                    Text("\(text.count) / \(limit)")
                        .font(WallFont.stamp(11))
                        .foregroundStyle(WallTheme.paper.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }

                Color.clear.frame(height: 70)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PlateButton(title: "SEND BUZZ BACK", systemImage: "paperplane.fill", tint: WallTheme.teal) {
                submit()
            }
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") { isWriting = false }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var confirmation: some View {
        VStack(spacing: 18) {
            Text("💬")
                .font(.system(size: 56))
            StencilTitle(text: "BUZZ BACK SENT", size: 26, color: WallTheme.paper)
                .multilineTextAlignment(.center)
            Text("Your two cents are stuck to the wall.")
                .font(WallFont.marker(15))
                .foregroundStyle(WallTheme.paper.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func submit() {
        isWriting = false
        store.addBuzzBack(buzzID: buzz.id, text: text)
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            didSubmit = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            dismiss()
        }
    }
}
