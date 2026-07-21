//
//  CatalogBackgroundMode.swift
//  RiveTestApp
//
//  The selectable catalog page backgrounds (matches the web reference's bg switcher):
//  solid black, solid dark gray (#121212), a checkerboard pattern to visualize transparency,
//  or a truly transparent background.
//

import SwiftUI
import RiveRuntime

enum CatalogBackgroundMode: String, CaseIterable, Identifiable {
    case black
    case darkGray
    case checker
    case transparent

    var id: String { rawValue }

    /// The solid SwiftUI color for this mode, or `nil` for modes that are not a solid color
    /// (e.g. the checkerboard pattern).
    var solidColor: SwiftUI.Color? {
        switch self {
        case .black:
            return .black
        case .darkGray:
            return SwiftUI.Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
        case .checker:
            return nil
        case .transparent:
            return .clear
        }
    }

    /// The background color to bake directly into each Rive render, so transparent artwork
    /// composites cleanly in a single pass instead of showing a tinted edge. Checker and
    /// transparent modes use a fully transparent Rive background so the pattern or underlying
    /// content shows through as intended.
    var riveBackgroundColor: RiveRuntime.Color {
        switch self {
        case .black, .darkGray:
            // Safe to force unwrap because these cases always return a solidColor.
            return RiveRuntime.Color(swiftUIColor: solidColor!)
        case .checker, .transparent:
            return RiveRuntime.Color(red: 0, green: 0, blue: 0, alpha: 0)
        }
    }

    var label: String {
        switch self {
        case .black: return "Black"
        case .darkGray: return "Dark Gray"
        case .checker: return "Checker"
        case .transparent: return "Transparent"
        }
    }

    var systemImage: String {
        switch self {
        case .black: return "circle.fill"
        case .darkGray: return "circle.fill"
        case .checker: return "checkerboard.rectangle"
        case .transparent: return "circle.dashed"
        }
    }

    @ViewBuilder
    var swatch: some View {
        switch self {
        case .black, .darkGray:
            solidColor
        case .checker:
            CheckerboardBackground(tileSize: 6)
        case .transparent:
            // Use a checkerboard swatch to communicate “transparent” in the picker,
            // but the actual full-bleed background will be Color.clear.
            CheckerboardBackground(tileSize: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }
}
