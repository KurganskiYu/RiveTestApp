//
//  CodeSnippetView.swift
//  RiveTestApp
//
//  Sheet that shows a generated, self-contained SwiftUI embed snippet for one CatalogItem, with
//  actions to copy it to the clipboard or share/save it as a real `.swift` file.
//

import SwiftUI
import UIKit

struct CodeSnippetView: View {
    let item: CatalogItem

    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""
    @State private var fileURL: URL?
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(code)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.darkGray))
            .navigationTitle("Embed Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        UIPasteboard.general.string = code
                        didCopy = true
                    } label: {
                        Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    }

                    Spacer()

                    if let fileURL {
                        ShareLink(item: fileURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .task {
            code = RiveCodeSnippetGenerator.generate(for: item)
            fileURL = writeTempFile()
        }
    }

    private func writeTempFile() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(RiveCodeSnippetGenerator.fileName(for: item))
        do {
            try code.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
