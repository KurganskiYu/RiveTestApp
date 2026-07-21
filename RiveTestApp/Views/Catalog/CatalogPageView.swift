//
//  CatalogPageView.swift
//  RiveTestApp
//
//  A single catalog page: up to 8 items laid out as 4 columns x 2 rows.
//

import SwiftUI

struct CatalogPageView: View {
    let items: [CatalogItem]
    let isActive: Bool
    let backgroundMode: CatalogBackgroundMode

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
        count: 4
    )

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        CatalogThumbnailView(item: item, isActive: isActive, backgroundMode: backgroundMode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            Spacer(minLength: 0)
        }
    }
}
