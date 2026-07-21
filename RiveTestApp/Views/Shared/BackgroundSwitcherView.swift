//
//  BackgroundSwitcherView.swift
//  RiveTestApp
//
//  Reusable row of background-mode swatch buttons, shared by the catalog and detail screens.
//

import SwiftUI

struct BackgroundSwitcherView: View {
    @Binding var mode: CatalogBackgroundMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CatalogBackgroundMode.allCases) { candidate in
                Button {
                    mode = candidate
                } label: {
                    candidate.swatch
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2)
                                .opacity(candidate == mode ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(candidate.label)
            }
        }
    }
}

/// Renders the currently selected background mode full-bleed (solid color or checker pattern).
struct RiveBackgroundView: View {
    let mode: CatalogBackgroundMode

    var body: some View {
        if let color = mode.solidColor {
            color
        } else {
            CheckerboardBackground()
        }
    }
}
