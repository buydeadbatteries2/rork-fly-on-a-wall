//
//  MyHiveScreen.swift
//  FlyOnAWall
//
//  The current user's own Hive — the reusable HiveScreen pointed at "me".
//

import SwiftUI

struct MyHiveScreen: View {
    @Binding var path: [WallRoute]
    @Environment(WallStore.self) private var store

    var body: some View {
        HiveScreen(flyID: store.me.id, path: $path)
    }
}
