//
//  CatalogThumbnailView.swift
//  RiveTestApp
//
//  A single non-interactive catalog tile: renders a live (but input-locked) Rive animation
//  at its natural aspect ratio, with the file name shown below it.
//

import SwiftUI
import RiveRuntime

struct CatalogThumbnailView: View {
    let item: CatalogItem
    let isActive: Bool
    let backgroundMode: CatalogBackgroundMode

    @State private var rive: Rive?
    @State private var loadError: Error?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if let rive {
                    RiveUIViewRepresentable(rive: rive)
                        .allowsHitTesting(false)
                } else if loadError != nil {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }

                // Sits above the Rive view so taps land on our own SwiftUI hit-testing (the
                // wrapped Rive UIKit view can otherwise swallow touches even with
                // `allowsHitTesting(false)`), letting the whole tile — not just the caption —
                // navigate to the detail screen.
                Color.clear
                    .contentShape(Rectangle())
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .aspectRatio(aspectRatio, contentMode: .fit)

            Text(item.displayName)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .task(id: isActive) {
            if isActive {
                async let loading: Void = loadIfNeeded()

                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }

                await loading

                guard !Task.isCancelled,
                      let trigger = item.trigger,
                      let viewModelInstance = rive?.viewModelInstance else {
                    return
                }

                viewModelInstance.fire(trigger: TriggerProperty(path: trigger))
            } else {
                rive = nil
            }
        }
        .onChange(of: backgroundMode) { _, newMode in
            rive?.backgroundColor = newMode.riveBackgroundColor
        }
    }

    private var aspectRatio: CGFloat {
        guard item.size.width > 0, item.size.height > 0 else { return 1 }
        return item.size.width / item.size.height
    }

    private func loadIfNeeded() async {
        guard rive == nil else { return }
        do {
            rive = try await RiveLoader.loadRive(
                resourceName: item.src,
                artboard: item.artboardName,
                stateMachine: item.stateMachineName,
                backgroundColor: backgroundMode.riveBackgroundColor
            )
        } catch {
            loadError = error
        }
    }
}
