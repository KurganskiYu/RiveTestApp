//
//  CatalogItem.swift
//  RiveTestApp
//
//  Data model for a single Rive animation entry parsed from _videos.csv.
//

import CoreGraphics
import Foundation

/// A single bindable/controllable parameter declared for a catalog item.
///
/// The new Rive Apple runtime only supports Data Binding (ViewModel properties) — there is no
/// legacy "state machine input" API. So CSV tokens `num`/`bol` are treated identically to
/// `v_num`/`v_bol`: both become ViewModel Number/Boolean properties addressed by name.
enum ParamSpec: Hashable, Identifiable {
    case number(name: String, defaultValue: Double?, range: ClosedRange<Double>?, precision: Int)
    case boolean(name: String, defaultValue: Bool?)
    case string(name: String, defaultValue: String?)
    case color(name: String, defaultValue: String?)
    case image(name: String, defaultValue: String?)
    /// Parsed for completeness but not rendered in the parameters UI (matches the web reference,
    /// which also does not wire up live list editing).
    case list(name: String, innerType: String, innerName: String)

    var id: String { name }

    var name: String {
        switch self {
        case .number(let name, _, _, _): return name
        case .boolean(let name, _): return name
        case .string(let name, _): return name
        case .color(let name, _): return name
        case .image(let name, _): return name
        case .list(let name, _, _): return name
        }
    }
}

/// A single row from `_videos.csv`, describing one Rive animation to show in the catalog.
struct CatalogItem: Identifiable, Hashable {
    /// The `.riv` file name (without extension), used both as a unique id and as the bundle
    /// resource name to load.
    let src: String
    /// The natural size of the main animation, as declared in the CSV `size` column.
    let size: CGSize
    /// The size of an internal "preview" artboard, if the CSV `preview` column specifies one.
    /// When set, the preview is rendered from the same file using an artboard literally named
    /// "preview". When nil, an external `<src>_preview.riv` file may still exist in the bundle.
    let previewSize: CGSize?
    /// State machine name to use; defaults to "State Machine 1" when not specified in the CSV.
    let stateMachineName: String
    /// Artboard name to use; nil means "use the file/artboard default" (CSV `artboard:-`).
    /// Defaults to "main" when the CSV row has no `artboard:` token at all.
    let artboardName: String?
    /// Name of a trigger property to fire, if the CSV row declares one.
    let trigger: String?
    /// Free-form note, if declared.
    let note: String?
    /// Bindable parameters declared for this item, in CSV column order.
    let inputs: [ParamSpec]

    var id: String { src }

    var displayName: String {
        src.replacingOccurrences(of: "_", with: " ")
    }

    static func == (lhs: CatalogItem, rhs: CatalogItem) -> Bool {
        lhs.src == rhs.src
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(src)
    }
}
