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
        repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
        count: 3
    )

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        CatalogThumbnailView(item: item, isActive: isActive, backgroundMode: backgroundMode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            Spacer(minLength: 0)
        }
        //.padding(.top, -20)
    }
}
