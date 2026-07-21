//
//  CheckerboardBackground.swift
//  RiveTestApp
//
//  A simple checkerboard pattern used to visualize transparent regions of Rive artwork,
//  matching the web reference's checker background mode.
//

import SwiftUI

struct CheckerboardBackground: View {
    var tileSize: CGFloat = 5
    var darkColor: SwiftUI.Color = .black
    var lightColor: SwiftUI.Color = SwiftUI.Color(white: 0.04)

    var body: some View {
        Canvas { context, size in
            let columns = Int((size.width / tileSize).rounded(.up)) + 1
            let rows = Int((size.height / tileSize).rounded(.up)) + 1
            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: CGFloat(column) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(Path(rect), with: .color(lightColor))
                }
            }
        }
        .background(darkColor)
    }
}
