//
//  ConnectFlyFlow.swift
//  FlyOnAWall
//
//  Propose that two buzzes may be talking about the same thing:
//  pick a buzz → say what the connection is → CHECK CONNECTION →
//  local deterministic analysis → the two Flies' buzzes converge → reveal.
//  Buzz similarity only. Never identification of people.
//

import SwiftUI

struct ConnectFlyFlow: View {
    let focusBuzzID: String
    @Binding var path: [WallRoute]

    @Environment(WallStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var noticeFocused: Bool

    private enum Step {
        case pick
        case clues
        case analyzing
        case result
    }

    @State private var step: Step = .pick
    @State private var search: String = ""
    @State private var filter: BuzzCategory?
    @State private var targetID: String?
    @State private var selectedClues: Set<ConnectionClue> = []
    @State private var notice: String = ""
    @State private var resultLink: FlyConnection?
    @State private var converged: Bool = false

    private var focus: Buzz? { store.buzz(id: focusBuzzID) }
    private var target: Buzz? { targetID.flatMap { store.buzz(id: $0) } }

    private var candidates: [Buzz] {
        store.buzzes
            .filter { $0.id != focusBuzzID }
            .filter { buzz in filter.map({ buzz.category == $0 }) ?? true }
            .filter { buzz in
                search.isEmpty
                    ? true
                    : buzz.text.localizedCaseInsensitiveContains(search)
                        || buzz.authorUsername.localizedCaseInsensitiveContains(search)
            }
    }

    var body: some View {
        ZStack {
            WallBackdrop(tint: FlyStatus.connected.tint, tintStrength: 0.12, dim: WallBackdrop.modalDim)

            switch step {
            case .pick: picker
            case .clues: clueForm
            case .analyzing: analyzing
            case .result: reveal
            }
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Step 1: picker

    private var picker: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                StencilTitle(text: "CONNECT A BUZZ", size: 30)
                Text("Which other buzz might be talking about the same thing?")
                    .font(WallFont.marker(14))
                    .foregroundStyle(WallTheme.ink.opacity(0.85))
            }
            .padding(.top, 10)

            searchField

            filterChips

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(candidates) { buzz in
                        candidateRow(buzz)
                    }
                    if candidates.isEmpty {
                        Text("No buzzes match that search.")
                            .font(WallFont.marker(15, weight: .regular))
                            .foregroundStyle(WallTheme.inkSoft)
                            .padding(.top, 26)
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(WallTheme.inkSoft)
            TextField("Search the wall...", text: $search)
                .font(WallFont.marker(15, weight: .regular))
                .foregroundStyle(WallTheme.ink)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(WallTheme.paper.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.2))
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip(title: "ALL", emoji: nil, tint: WallTheme.ink, isActive: filter == nil) {
                    filter = nil
                }
                ForEach(BuzzCategory.allCases) { category in
                    chip(title: category.title, emoji: category.emoji, tint: category.tint, isActive: filter == category) {
                        filter = filter == category ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, emoji: String?, tint: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji {
                    Text(emoji).font(.system(size: 11))
                }
                Text(title)
                    .font(WallFont.stamp(11))
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink.opacity(0.85))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? tint : WallTheme.paper.opacity(0.9))
                    .overlay(Capsule().stroke(tint.opacity(isActive ? 1 : 0.5), lineWidth: 1.2))
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.93))
    }

    private func candidateRow(_ buzz: Buzz) -> some View {
        let existing = store.connection(between: focusBuzzID, and: buzz.id) != nil
        let status = store.profile(id: buzz.authorID)?.currentStatus ?? .new
        return Button {
            Haptics.tap()
            targetID = buzz.id
            step = .clues
        } label: {
            HStack(spacing: 11) {
                FlyView(status: status, size: 24, wingsBeating: false)
                    .frame(width: 42, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(buzz.authorUsername)
                            .font(WallFont.stamp(11))
                            .foregroundStyle(WallTheme.rust)
                        Text(buzz.category.title)
                            .font(WallFont.stamp(8))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(buzz.category.tint.opacity(0.9)))
                    }
                    Text(buzz.text)
                        .font(WallFont.marker(14, weight: .regular))
                        .foregroundStyle(WallTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if existing {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(FlyStatus.connected.tint)
                }
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(WallTheme.paper.opacity(0.94))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(WallTheme.inkSoft.opacity(0.4), lineWidth: 1.1))
                    .wallShadow(radius: 5, y: 3)
            }
            .opacity(existing ? 0.55 : 1)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .disabled(existing)
        .accessibilityLabel(existing ? "\(buzz.authorUsername)'s buzz. Already linked." : "\(buzz.authorUsername)'s buzz. \(buzz.text)")
    }

    // MARK: - Step 2: clues

    private var clueForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    StencilTitle(text: "WHAT'S THE\nCONNECTION?", size: 27)
                    if let target {
                        Text("Between this buzz and \(target.authorUsername)'s. Pick everything you noticed.")
                            .font(WallFont.marker(14))
                            .foregroundStyle(WallTheme.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 10)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(ConnectionClue.allCases) { clue in
                        clueChip(clue)
                    }
                }

                noticeField

                PlateButton(title: "CHECK CONNECTION", systemImage: "link") {
                    Haptics.tap()
                    noticeFocused = false
                    runAnalysis()
                }
                .opacity(selectedClues.isEmpty ? 0.5 : 1)
                .disabled(selectedClues.isEmpty)

                Button {
                    Haptics.tap()
                    step = .pick
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .black))
                        Text("PICK A DIFFERENT BUZZ")
                            .font(WallFont.stamp(11))
                    }
                    .foregroundStyle(WallTheme.inkSoft)
                }
                .buttonStyle(PressableButtonStyle())

                Color.clear.frame(height: 30)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func clueChip(_ clue: ConnectionClue) -> some View {
        let isActive = selectedClues.contains(clue)
        return Button {
            Haptics.tap()
            if isActive {
                selectedClues.remove(clue)
            } else {
                selectedClues.insert(clue)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: clue.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(clue.rawValue)
                    .font(WallFont.stamp(11))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isActive ? .white : WallTheme.ink.opacity(0.85))
            .padding(.horizontal, 11)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? FlyStatus.connected.tint : WallTheme.paper.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(isActive ? FlyStatus.connected.tint : WallTheme.inkSoft.opacity(0.45), lineWidth: 1.3)
                    )
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.95))
        .accessibilityLabel(clue.rawValue)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var noticeField: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("WHAT DID YOU NOTICE? (OPTIONAL)")
                .font(WallFont.stamp(10))
                .foregroundStyle(WallTheme.inkSoft)
            TextField("e.g. Same night, same burnt-sugar smell...", text: $notice, axis: .vertical)
                .font(WallFont.marker(15, weight: .regular))
                .foregroundStyle(WallTheme.ink)
                .lineLimit(2...4)
                .focused($noticeFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(WallTheme.paper.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(WallTheme.inkSoft.opacity(0.45), lineWidth: 1.2))
                }
                .onChange(of: notice) { _, newValue in
                    if newValue.count > 140 {
                        notice = String(newValue.prefix(140))
                    }
                }
        }
    }

    // MARK: - Step 3: analyzing

    /// The two Flies' buzzes glide toward each other, then the verdict lands.
    private var analyzing: some View {
        VStack(spacing: 26) {
            Spacer()

            GeometryReader { proxy in
                let midY = proxy.size.height / 2
                let gap: CGFloat = converged ? 74 : proxy.size.width - 96
                HStack {
                    if let focus, let target {
                        FlyView(status: status(of: focus), size: 34)
                            .frame(width: 60, alignment: .trailing)
                        Spacer(minLength: 0)
                        FlyView(status: status(of: target), size: 34)
                            .frame(width: 60, alignment: .leading)
                    }
                }
                .position(x: proxy.size.width / 2, y: midY)
                .frame(width: gap)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 120)

            VStack(spacing: 6) {
                Text("COMPARING DETAILS...")
                    .font(WallFont.stencil(22))
                    .foregroundStyle(WallTheme.paper)
                Text("Just the buzzes. Nobody is being identified.")
                    .font(WallFont.marker(13, weight: .regular))
                    .foregroundStyle(WallTheme.paper.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 26)
        .onAppear(perform: runConvergence)
    }

    private func runConvergence() {
        guard !reduceMotion else {
            finishAnalysis()
            return
        }
        withAnimation(.spring(response: 1.2, dampingFraction: 0.75)) {
            converged = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            finishAnalysis()
        }
    }

    // MARK: - Step 4: reveal

    private var reveal: some View {
        VStack(spacing: 16) {
            Spacer()

            if let link = resultLink {
                Text(link.strength == .weakBuzz ? "🪰 POSSIBLE BUZZ" : "🪰 CONNECTION FOUND")
                    .font(WallFont.stencil(30))
                    .foregroundStyle(WallTheme.paper)
                    .multilineTextAlignment(.center)

                Text(link.strength.title)
                    .font(WallFont.stencil(22))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(link.strength.lineColor)
                            .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1.4))
                    )
                    .wallShadow(radius: 8, y: 4)

                Text(link.strength.blurb)
                    .font(WallFont.marker(16))
                    .foregroundStyle(WallTheme.paper)
                    .multilineTextAlignment(.center)

                clueSummary(link)

                if let safety = link.strength.safetyLine {
                    Text(safety)
                        .font(WallFont.marker(12, weight: .regular))
                        .foregroundStyle(WallTheme.paper.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if link.strength != .weakBuzz, let swarm = swarmBanner(for: link) {
                    swarmFormed(swarm)
                }
            }

            Spacer()

            PlateButton(title: "VIEW ON BOARD", systemImage: "link") {
                Haptics.success()
                dismiss()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func clueSummary(_ link: FlyConnection) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(link.overlappingClues) { clue in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WallTheme.teal)
                    Text(clue.rawValue)
                        .font(WallFont.marker(14, weight: .medium))
                        .foregroundStyle(WallTheme.paper)
                }
            }
            ForEach(link.conflictingClues, id: \.self) { conflict in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WallTheme.rust)
                    Text(conflict)
                        .font(WallFont.marker(14, weight: .medium))
                        .foregroundStyle(WallTheme.paper)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.ink.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.18), lineWidth: 1))
        }
    }

    /// Shown when the new connection tips a 3+ buzz cluster into a Swarm.
    private func swarmFormed(_ swarm: Swarm) -> some View {
        VStack(spacing: 6) {
            Text("🪰 SWARM FORMING")
                .font(WallFont.stamp(12))
                .foregroundStyle(FlyStatus.connected.tint)
            Text(swarm.title)
                .font(WallFont.stencil(20))
                .foregroundStyle(WallTheme.paper)
            Text("\(store.flyCount(for: swarm)) FLIES NOW CIRCLING TOGETHER")
                .font(WallFont.stamp(10))
                .foregroundStyle(WallTheme.paper.opacity(0.8))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(WallTheme.paper.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(FlyStatus.connected.tint.opacity(0.7), lineWidth: 1.4))
        }
    }

    private func swarmBanner(for link: FlyConnection) -> Swarm? {
        guard let swarmID = link.swarmID else { return nil }
        return store.swarms.first { $0.id == swarmID }
    }

    // MARK: - Behaviour

    private func status(of buzz: Buzz) -> FlyStatus {
        store.profile(id: buzz.authorID)?.currentStatus ?? .new
    }

    /// Runs the local deterministic analyzer and stores the connection. The
    /// convergence animation plays while the (instant) result waits to reveal.
    private func runAnalysis() {
        guard let targetID,
              let link = store.proposeConnection(sourceID: focusBuzzID, targetID: targetID, clues: orderedClues)
        else { return }
        resultLink = link
        withAnimation(.easeOut(duration: 0.25)) {
            step = .analyzing
        }
    }

    private func finishAnalysis() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            step = .result
        }
    }

    /// Most specific first, matching how the analyzer lists them.
    private var orderedClues: [ConnectionClue] {
        selectedClues.sorted { $0.weight > $1.weight }
    }
}
