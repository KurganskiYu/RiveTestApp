//
//  CatalogBackgroundMode.swift
//  RiveTestApp
//
//  The selectable catalog page backgrounds, driven by `bg_button.riv`'s "bgNum" ViewModel
//  property (matches the web reference's bg switcher exactly): solid black, solid dark gray
//  (#121212), or a checkerboard pattern to visualize transparency.
//

import SwiftUI
import RiveRuntime

enum CatalogBackgroundMode: String, CaseIterable, Identifiable {
    case checker
    case black
    case darkGray

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
        }
    }

    /// The background color to bake directly into each Rive render, so transparent artwork
    /// composites cleanly in a single pass instead of showing a tinted edge. The checker mode
    /// uses a fully transparent Rive background so the pattern shows through as intended.
    var riveBackgroundColor: RiveRuntime.Color {
        switch self {
        case .black, .darkGray:
            // Safe to force unwrap because these cases always return a solidColor.
            return RiveRuntime.Color(swiftUIColor: solidColor!)
        case .checker:
            return RiveRuntime.Color(red: 0, green: 0, blue: 0, alpha: 0)
        }
    }

    /// The value `bg_button.riv` uses for its "bgNum" ViewModel Number property for this mode
    /// (matches `WebTester/_generate_html.py`'s `get_bg_button_html`: 1=checker, 2=black,
    /// 3=dark gray).
    var bgButtonNumber: Double {
        switch self {
        case .checker: return 1
        case .black: return 2
        case .darkGray: return 3
        }
    }

    /// Reverse mapping from a "bgNum" value read off `bg_button.riv` back to a mode.
    init?(bgButtonNumber: Double) {
        switch Int(bgButtonNumber.rounded()) {
        case 1: self = .checker
        case 2: self = .black
        case 3: self = .darkGray
        default: return nil
        }
    }
}
