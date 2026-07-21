//
//  BundleResource.swift
//  RiveTestApp
//
//  Resolves bundled resource files regardless of whether Xcode's synchronized group flattens
//  or preserves the on-disk `riv/` and `img/` subfolders when copying into the app bundle.
//

import Foundation

enum BundleResource {
    /// Looks up a resource by name/extension, first inside `subdirectory`, then at the bundle
    /// root, so callers don't need to know how the folder was copied into the app bundle.
    static func url(name: String, extension ext: String, subdirectory: String, bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
            ?? bundle.url(forResource: name, withExtension: ext)
    }

    static func exists(name: String, extension ext: String, subdirectory: String, bundle: Bundle = .main) -> Bool {
        url(name: name, extension: ext, subdirectory: subdirectory, bundle: bundle) != nil
    }

    static func data(name: String, extension ext: String, subdirectory: String, bundle: Bundle = .main) throws -> Data {
        guard let url = url(name: name, extension: ext, subdirectory: subdirectory, bundle: bundle) else {
            throw BundleResourceError.notFound(name: name, extension: ext)
        }
        return try Data(contentsOf: url)
    }
}

enum BundleResourceError: LocalizedError {
    case notFound(name: String, extension: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let name, let ext):
            return "Resource '\(name).\(ext)' not found in app bundle."
        }
    }
}
