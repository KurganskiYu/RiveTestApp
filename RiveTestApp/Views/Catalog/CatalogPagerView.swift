//
//  CatalogPagerView.swift
//  RiveTestApp
//
//  Swipeable pager over all catalog pages. Only the currently-visible page loads real Rive
//  content (capping concurrent Rive instances at itemsPerPage), matching the plan's decision
//  to keep resource usage bounded.
//

import SwiftUI

struct CatalogPagerView: View {
    let store: CatalogStore

    @State private var currentPage = 0
    @State private var backgroundMode: CatalogBackgroundMode = .black

    var body: some View {
        ZStack {
            RiveBackgroundView(mode: backgroundMode)
                .ignoresSafeArea()

            Group {
                if let loadError = store.loadError {
                    ContentUnavailableView(
                        "Couldn't load catalog",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if store.pages.isEmpty {
                    ProgressView()
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(Array(store.pages.enumerated()), id: \.offset) { index, page in
                            CatalogPageView(items: page, isActive: index == currentPage, backgroundMode: backgroundMode)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .ignoresSafeArea(.all, edges: .top)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            BackgroundSwitcherView(mode: $backgroundMode)
                .padding(.leading, 20)
                .padding(.bottom, 20)
        }
        //.navigationTitle("Rive Animations")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Rive Animations")
                    .font(.system(.title, weight: .thin))
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        // The catalog always paints its own black/dark/checker background regardless of the
        // system appearance, so force a dark color scheme here too — this keeps semantic colors
        // like `.secondary` text legible against it (e.g. the caption under each thumbnail).
        .environment(\.colorScheme, .dark)
    }
}
