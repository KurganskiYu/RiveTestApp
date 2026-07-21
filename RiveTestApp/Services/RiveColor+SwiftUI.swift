//
//  RiveColor+SwiftUI.swift
//  RiveTestApp
//
//  Bridges SwiftUI.Color <-> RiveRuntime.Color, since both modules export a type named "Color".
//

import SwiftUI
import RiveRuntime

extension RiveRuntime.Color {
    /// Creates a Rive color from a SwiftUI color by extracting its RGBA components.
    init(swiftUIColor color: SwiftUI.Color) {
        #if canImport(UIKit)
        let platformColor = UIColor(color)
        #else
        let platformColor = NSColor(color)
        #endif
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(
            red: UInt8(clamping: Int((red * 255).rounded())),
            green: UInt8(clamping: Int((green * 255).rounded())),
            blue: UInt8(clamping: Int((blue * 255).rounded())),
            alpha: UInt8(clamping: Int((alpha * 255).rounded()))
        )
    }
}

extension SwiftUI.Color {
    /// Parses a `#RRGGBB` or `#RRGGBBAA` hex string, if present; returns nil for anything else
    /// (including empty strings), so callers can fall back to a random default.
    init?(hex: String?) {
        guard var hex = hex?.trimmingCharacters(in: .whitespaces), !hex.isEmpty else { return nil }
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }

        let hasAlpha = hex.count == 8
        let red = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? Double(value & 0xFF) / 255 : 1
        self = SwiftUI.Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// A visually distinct random color, used as the default for `col:` parameters that don't
    /// specify one (matches the web reference's random-default behavior).
    static func randomVivid() -> SwiftUI.Color {
        SwiftUI.Color(hue: .random(in: 0...1), saturation: 0.65, brightness: 0.9)
    }
}
