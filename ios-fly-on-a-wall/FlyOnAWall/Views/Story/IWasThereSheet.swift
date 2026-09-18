//
//  IWasThereSheet.swift
//  FlyOnAWall
//
//  OH REALLY? — collecting a witness angle plus a note.
//

import SwiftUI

struct IWasThereSheet: View {
    let buzz: Buzz

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWriting: Bool
    @State private var angle: WitnessAngle?
    @State private var note: String = ""
    @State private var didSubmit: Bool = false

    private let limit: Int = 300

    var body: some View {
        ZStack {
            WallBackdrop(tint: WallTheme.rust, tintStrength: 0.14)

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
                        Text("OH REALLY?")
                            .font(WallFont.stencil(36))
                            .foregroundStyle(WallTheme.ink)
                        Text("👀").font(.system(size: 30))
                    }
                    Text("How were you involved?")
                        .font(WallFont.marker(17))
                        .foregroundStyle(WallTheme.ink.opacity(0.85))
                }
                .padding(.top, 10)

                TapedPaper(rotation: -0.8, padding: 14) {
                    Text(buzz.text)
                        .font(WallFont.marker(14, weight: .regular))
                        .foregroundStyle(WallTheme.inkSoft)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 8) {
                    ForEach(WitnessAngle.allCases) { option in
                        angleRow(option)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    PatchedLabel(text: "ADD YOUR SIDE", size: 15)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(WallTheme.paper.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.2))

                        if note.isEmpty {
                            Text("What actually happened...")
                                .font(WallFont.marker(15, weight: .regular))
                                .foregroundStyle(WallTheme.inkSoft.opacity(0.6))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $note)
                            .focused($isWriting)
                            .font(WallFont.marker(15, weight: .regular))
                            .foregroundStyle(WallTheme.ink)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .onChange(of: note) { _, newValue in
                                if newValue.count > limit {
                                    note = String(newValue.prefix(limit))
                                }
                            }
                    }
                    .frame(height: 140)
                    .wallShadow(radius: 8, y: 5)

                    Text("\(note.count) / \(limit)")
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
            PlateButton(title: "SEND IT IN", systemImage: "paperplane.fill") {
                submit()
            }
            .opacity(angle == nil ? 0.5 : 1)
            .disabled(angle == nil)
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

    private func angleRow(_ option: WitnessAngle) -> some View {
        let isSelected = angle == option
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                angle = option
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isSelected ? .white : WallTheme.ink.opacity(0.7))
                    .frame(width: 26)
                Text(option.rawValue)
                    .font(WallFont.marker(16))
                    .foregroundStyle(isSelected ? .white : WallTheme.ink)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? WallTheme.rust : WallTheme.paper.opacity(0.93))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? WallTheme.ink.opacity(0.55) : WallTheme.inkSoft.opacity(0.4), lineWidth: 1.4)
                    )
            }
            .wallShadow(radius: 5, y: 3)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var confirmation: some View {
        VStack(spacing: 18) {
            FlyView(status: .iWasThere, size: 64)
                .frame(height: 90)
            StencilTitle(text: "YOUR SIDE IS ON THE WALL", size: 26, color: WallTheme.paper)
                .multilineTextAlignment(.center)
            Text("Another fly just got a lot more interesting.")
                .font(WallFont.marker(15))
                .foregroundStyle(WallTheme.paper.opacity(0.9))
                .multilineTextAlignment(.center)
            PlateButton(title: "BACK TO THE FLY", systemImage: "arrow.uturn.left") {
                dismiss()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 28)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func submit() {
        guard let angle else { return }
        isWriting = false
        store.addWitness(buzzID: buzz.id, angle: angle, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            didSubmit = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }
}
