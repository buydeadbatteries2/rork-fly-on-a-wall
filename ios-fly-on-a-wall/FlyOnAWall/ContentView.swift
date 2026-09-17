//
//  ContentView.swift
//  FlyOnAWall
//
//  App shell: five wall sections behind a custom metal tab strip.
//

import SwiftUI

struct ContentView: View {
    @State private var store = WallStore()
    @State private var selection: AppTab = .wall
    @State private var wallPath: [WallRoute] = []
    @State private var swarmPath: [WallRoute] = []
    @State private var explorePath: [WallRoute] = []
    @State private var hivePath: [WallRoute] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .wall:
                    NavigationStack(path: $wallPath) {
                        TheWallScreen(path: $wallPath)
                            .wallDestinations(path: $wallPath)
                    }
                case .swarms:
                    NavigationStack(path: $swarmPath) {
                        SwarmsScreen(path: $swarmPath)
                            .wallDestinations(path: $swarmPath)
                    }
                case .post:
                    PostAFlyScreen()
                case .explore:
                    NavigationStack(path: $explorePath) {
                        ExploreScreen(path: $explorePath)
                            .wallDestinations(path: $explorePath)
                    }
                case .hive:
                    NavigationStack(path: $hivePath) {
                        MyHiveScreen(path: $hivePath)
                            .wallDestinations(path: $hivePath)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !hidesTabBar {
                WallTabBar(selection: $selection)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.24), value: hidesTabBar)
        .background(WallTheme.warmGray)
        .environment(store)
    }

    /// Story detail owns the bottom edge, so the tab strip steps aside there.
    private var hidesTabBar: Bool {
        guard let top = activePath.last else { return false }
        if case .story = top { return true }
        return false
    }

    private var activePath: [WallRoute] {
        switch selection {
        case .wall: wallPath
        case .swarms: swarmPath
        case .explore: explorePath
        case .hive: hivePath
        case .post: []
        }
    }
}

private struct WallDestinations: ViewModifier {
    @Binding var path: [WallRoute]

    func body(content: Content) -> some View {
        content.navigationDestination(for: WallRoute.self) { route in
            switch route {
            case .category(let category):
                CategoryWallScreen(category: category, path: $path)
            case .story(let id):
                StoryDetailScreen(storyID: id, path: $path)
            case .swarm(let id):
                SwarmDetailScreen(swarmID: id, path: $path)
            case .connectionBoard(let id):
                ConnectionBoardScreen(storyID: id, path: $path)
            }
        }
    }
}

extension View {
    /// Shared push destinations so every stack behaves identically.
    func wallDestinations(path: Binding<[WallRoute]>) -> some View {
        modifier(WallDestinations(path: path))
    }
}

#Preview {
    ContentView()
}
