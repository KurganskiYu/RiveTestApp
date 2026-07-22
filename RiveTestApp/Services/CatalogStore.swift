//
//  CatalogStore.swift
//  RiveTestApp
//
//  Loads and parses the bundled _videos.csv once, exposing items paginated
//  8-per-page for the catalog UI.
//

import Foundation
import Observation

@MainActor
@Observable
final class CatalogStore {
    /// Number of animations shown per catalog page (2 rows x 4 columns).
    static let itemsPerPage = 6

    private(set) var items: [CatalogItem] = []
    private(set) var pages: [[CatalogItem]] = []
    private(set) var loadError: String?

    init() {
        reload()
    }

    func reload() {
        guard let url = Bundle.main.url(forResource: "_videos", withExtension: "csv") else {
            loadError = "_videos.csv not found in app bundle."
            items = []
            pages = []
            return
        }

        do {
            let csvText = try String(contentsOf: url, encoding: .utf8)
            let parsed = CatalogCSVParser.parse(csvText: csvText)
            items = parsed
            pages = stride(from: 0, to: parsed.count, by: Self.itemsPerPage).map {
                Array(parsed[$0..<min($0 + Self.itemsPerPage, parsed.count)])
            }
            loadError = nil
        } catch {
            loadError = "Failed to read _videos.csv: \(error.localizedDescription)"
            items = []
            pages = []
        }
    }
}
