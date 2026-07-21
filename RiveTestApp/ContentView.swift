//
//  ContentView.swift
//  RiveTestApp
//
//  Created by Yuri Kurganski on 17.07.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var store = CatalogStore()

    var body: some View {
        NavigationStack {
            CatalogPagerView(store: store)
                .navigationDestination(for: CatalogItem.self) { item in
                    AnimationDetailView(item: item)
                }
        }
    }
}

#Preview {
    ContentView()
}
