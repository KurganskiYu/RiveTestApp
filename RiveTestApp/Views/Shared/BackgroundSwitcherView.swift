//
//  BackgroundSwitcherView.swift
//  RiveTestApp
//
//  A small, self-interactive `bg_button.riv` widget shared by the catalog and detail screens.
//  Its own artwork is driven by a "bgNum" ViewModel Number property (1=checker, 2=black,
//  3=dark gray) — mirrors `WebTester/_generate_html.py`'s `get_bg_button_html` exactly. We push
//  the screen's current mode into "bgNum" once loaded, then observe it for changes so taps on
//  the button (which it cycles internally) update our native background too.
//

import SwiftUI
import RiveRuntime

struct BackgroundSwitcherView: View {
    @Binding var mode: CatalogBackgroundMode

    @State private var rive: Rive?

    var body: some View {
        RiveUIViewRepresentable(rive: rive)
            .frame(width: 64, height: 64)
            .accessibilityLabel("Background switcher")
            .task {
                await loadIfNeeded()
            }
    }

    private func loadIfNeeded() async {
        let loadedRive: Rive
        if let existing = rive {
            loadedRive = existing
        } else if let loaded = try? await RiveLoader.loadRive(
            resourceName: "bg_button",
            artboard: "main",
            stateMachine: "State Machine 1"
        ) {
            loadedRive = loaded
            rive = loaded
        } else {
            return
        }

        guard let vmi = loadedRive.viewModelInstance else { return }
        let bgNum = NumberProperty(path: "bgNum")
        vmi.setValue(of: bgNum, to: Float(mode.bgButtonNumber))

        do {
            for try await value in vmi.valueStream(of: bgNum) {
                if let newMode = CatalogBackgroundMode(bgButtonNumber: Double(value)) {
                    mode = newMode
                }
            }
        } catch {
            // Stream cancelled or ended
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
