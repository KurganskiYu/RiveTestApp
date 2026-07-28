//
//  AnimationDetailViewModel.swift
//  RiveTestApp
//
//  Loads the main (and optional preview) Rive configuration for a catalog item, and bridges
//  ParamSpec values to Rive ViewModel properties.
//

import Foundation
import Observation
import SwiftUI
import RiveRuntime

enum DetailDisplayMode {
    case main
    case preview
}

@MainActor
@Observable
final class AnimationDetailViewModel {
    let item: CatalogItem

    private(set) var mainRive: Rive?
    private(set) var previewRive: Rive?
    var mode: DetailDisplayMode = .main
    private(set) var loadError: String?
    private(set) var isLoading = false

    /// The selected background (black/dark gray/checker), matching the catalog's switcher.
    /// Changing it live-updates already-loaded Rive objects instead of reloading them.
    var backgroundMode: CatalogBackgroundMode = .black {
        didSet {
            let color = backgroundMode.riveBackgroundColor
            mainRive?.backgroundColor = color
            previewRive?.backgroundColor = color
        }
    }

    var hasPreview: Bool { previewRive != nil }

    var numberValues: [String: Double] = [:]
    var boolValues: [String: Bool] = [:]
    var stringValues: [String: String] = [:]
    var colorValues: [String: SwiftUI.Color] = [:]
    var imageNames: [String: String] = [:]

    var currentRive: Rive? {
        mode == .preview ? (previewRive ?? mainRive) : mainRive
    }

    init(item: CatalogItem) {
        self.item = item
        seedDefaults()
    }

    private func seedDefaults() {
        for input in item.inputs {
            switch input {
            case .number(let name, let defaultValue, let range, _):
                let value = defaultValue ?? 0
                numberValues[name] = range.map { min(max(value, $0.lowerBound), $0.upperBound) } ?? value
            case .boolean(let name, let defaultValue):
                boolValues[name] = defaultValue ?? false
            case .string(let name, let defaultValue):
                stringValues[name] = defaultValue ?? ""
            case .color(let name, let defaultValue):
                colorValues[name] = SwiftUI.Color(hex: defaultValue) ?? .randomVivid()
            case .image(let name, let defaultValue):
                imageNames[name] = defaultValue ?? ""
            case .list:
                break
            }
        }
    }

    func load() async {
        guard mainRive == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Bake the currently selected background color directly into the Rive render so
        // anti-aliased/semi-transparent artwork composites cleanly in a single pass instead of
        // showing a tinted edge against whatever sits behind the animation view.
        let detailBackgroundColor = backgroundMode.riveBackgroundColor

        do {
            let rive = try await RiveLoader.loadRive(
                resourceName: item.src,
                artboard: item.artboardName,
                stateMachine: item.stateMachineName,
                backgroundColor: detailBackgroundColor
            )
            mainRive = rive
            await applyAllValues(to: rive)

            if let previewSource = RiveLoader.previewSource(for: item) {
                if let preview = try? await RiveLoader.loadRive(
                    resourceName: previewSource.resourceName,
                    artboard: previewSource.artboard,
                    stateMachine: item.stateMachineName,
                    backgroundColor: detailBackgroundColor
                ) {
                    previewRive = preview
                    await applyAllValues(to: preview)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Setters

    func setNumber(_ name: String, _ value: Double) {
        let range = item.inputs.first {
            guard case .number(let inputName, _, _, _) = $0 else { return false }
            return inputName == name
        }.flatMap { input -> ClosedRange<Double>? in
            guard case .number(_, _, let range, _) = input else { return nil }
            return range
        }
        let resolvedValue = range.map { min(max(value, $0.lowerBound), $0.upperBound) } ?? value
        numberValues[name] = resolvedValue
        applyToAll { $0.setValue(of: NumberProperty(path: name), to: Float(resolvedValue)) }
    }

    func setBool(_ name: String, _ value: Bool) {
        boolValues[name] = value
        applyToAll { $0.setValue(of: BoolProperty(path: name), to: value) }
    }

    func setString(_ name: String, _ value: String) {
        stringValues[name] = value
        applyToAll { $0.setValue(of: StringProperty(path: name), to: value) }
    }

    func setColor(_ name: String, _ value: SwiftUI.Color) {
        colorValues[name] = value
        let riveColor = RiveRuntime.Color(swiftUIColor: value)
        applyToAll { $0.setValue(of: ColorProperty(path: name), to: riveColor) }
    }

    func setImage(_ name: String, filename: String) {
        imageNames[name] = filename
        Task {
            guard let image = await decodeImage(named: filename) else { return }
            applyToAll { $0.setValue(of: ImageProperty(path: name), to: image) }
        }
    }

    func fireTrigger() {
        guard let name = item.trigger else { return }
        applyToAll { $0.fire(trigger: TriggerProperty(path: name)) }
    }

    // MARK: - Helpers

    private func applyToAll(_ block: (ViewModelInstance) -> Void) {
        if let vmi = mainRive?.viewModelInstance { block(vmi) }
        if let vmi = previewRive?.viewModelInstance { block(vmi) }
    }

    private func applyAllValues(to rive: Rive) async {
        guard let vmi = rive.viewModelInstance else { return }
        for (name, value) in numberValues {
            vmi.setValue(of: NumberProperty(path: name), to: Float(value))
        }
        for (name, value) in boolValues {
            vmi.setValue(of: BoolProperty(path: name), to: value)
        }
        for (name, value) in stringValues {
            vmi.setValue(of: StringProperty(path: name), to: value)
        }
        for (name, value) in colorValues {
            vmi.setValue(of: ColorProperty(path: name), to: RiveRuntime.Color(swiftUIColor: value))
        }
        for (name, filename) in imageNames where !filename.isEmpty {
            if let image = await decodeImage(named: filename) {
                vmi.setValue(of: ImageProperty(path: name), to: image)
            }
        }
    }

    private func decodeImage(named filename: String) async -> RiveRuntime.Image? {
        guard !filename.isEmpty else { return nil }
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        guard !ext.isEmpty,
              let data = try? BundleResource.data(name: name, extension: ext, subdirectory: "img"),
              let worker = try? await RiveWorkerProvider.shared.worker(),
              let image = try? await worker.decodeImage(from: data)
        else {
            return nil
        }
        return image
    }
}
