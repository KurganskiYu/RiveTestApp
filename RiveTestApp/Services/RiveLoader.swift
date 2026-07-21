//
//  RiveLoader.swift
//  RiveTestApp
//
//  Async helpers for turning a CatalogItem into a loaded Rive configuration, and for
//  resolving the correct preview source (internal "preview" artboard vs external
//  `<src>_preview.riv` file), mirroring the logic in WebTester/_generate_html.py.
//

import Foundation
import RiveRuntime

@MainActor
enum RiveLoader {
    /// Loads the `.riv` data for `resourceName` from the bundle (checking the `riv/` subfolder
    /// first, then the bundle root) and builds a fully configured `Rive` instance using the
    /// given artboard/state machine names (nil meaning "use the file/artboard default").
    ///
    /// `backgroundColor` is baked directly into the Rive render (rather than left fully
    /// transparent) so that anti-aliased/semi-transparent artwork composites cleanly against a
    /// known color in a single pass, instead of showing a tinted edge when later composited over
    /// whatever SwiftUI view sits behind it.
    static func loadRive(
        resourceName: String,
        artboard: String?,
        stateMachine: String?,
        backgroundColor: RiveRuntime.Color = RiveRuntime.Color(red: 0, green: 0, blue: 0, alpha: 0)
    ) async throws -> Rive {
        let data = try BundleResource.data(name: resourceName, extension: "riv", subdirectory: "riv")
        let worker = try await RiveWorkerProvider.shared.worker()
        let file = try await File(source: .data(data), worker: worker)
        let resolvedArtboard = try await file.createArtboard(artboard)
        let resolvedStateMachine = try await resolvedArtboard.createStateMachine(stateMachine)
        return try await Rive(
            file: file,
            artboard: resolvedArtboard,
            stateMachine: resolvedStateMachine,
            backgroundColor: backgroundColor
        )
    }

    /// Resolves the preview source for a catalog item, if one exists.
    /// - If the CSV `preview` column specified a size, the preview comes from the same file,
    ///   using an artboard literally named "preview" and the item's state machine.
    /// - Otherwise, if a `<src>_preview.riv` file exists in the bundle, it's used as the preview
    ///   source with the item's own artboard and state machine.
    static func previewSource(for item: CatalogItem) -> (resourceName: String, artboard: String?)? {
        if item.previewSize != nil {
            return (item.src, "preview")
        }
        let externalName = "\(item.src)_preview"
        if BundleResource.exists(name: externalName, extension: "riv", subdirectory: "riv") {
            return (externalName, item.artboardName)
        }
        return nil
    }
}
