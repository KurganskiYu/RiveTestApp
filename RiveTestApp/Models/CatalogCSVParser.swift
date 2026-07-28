//
//  CatalogCSVParser.swift
//  RiveTestApp
//
//  Swift port of the token parsing logic in WebTester/_generate_html.py
//  (load_csv_rows / parse_input_spec / parse_size / strip_quotes).
//

import CoreGraphics
import Foundation

enum CatalogCSVParser {
    static let defaultStateMachine = "State Machine 1"
    static let defaultArtboard = "main"

    private static let scalarKeys: Set<String> = ["sm", "artboard", "trigger", "note"]
    private static let inputTypePrefixes: Set<String> = ["num", "bol", "v_num", "v_bol", "txt", "col", "img", "list"]

    /// Parses the full contents of `_videos.csv` into catalog items.
    ///
    /// Mirrors the Python reference: the header row is skipped, rows are parsed leniently
    /// (missing columns default to empty), and the result is reversed so the most recently
    /// appended CSV rows appear first (matches `rows[::-1]` in `_generate_html.py`).
    static func parse(csvText: String) -> [CatalogItem] {
        let normalized = csvText.replacingOccurrences(of: "\r\n", with: "\n")
        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard !lines.isEmpty else { return [] }
        lines.removeFirst() // header

        var items: [CatalogItem] = []
        for rawLine in lines {
            if rawLine.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            guard let item = parseRow(rawLine) else { continue }
            items.append(item)
        }
        return items.reversed()
    }

    // MARK: - Row parsing

    private static func parseRow(_ rawLine: String) -> CatalogItem? {
        let fields = splitCSVLine(rawLine)
        guard !fields.isEmpty else { return nil }

        var src = fields[0].trimmingCharacters(in: .whitespaces)
        if src.lowercased().hasSuffix(".riv") {
            src = String(src.dropLast(4))
        }
        guard !src.isEmpty else { return nil }

        let sizeStr = fields.count > 1 ? fields[1].trimmingCharacters(in: .whitespaces) : ""
        let previewStr = fields.count > 2 ? fields[2].trimmingCharacters(in: .whitespaces) : ""

        var stateMachine: String?
        var artboardSpecified = false
        var artboardValue: String?
        var trigger: String?
        var note: String?
        var inputs: [ParamSpec] = []

        if fields.count > 3 {
            for rawToken in fields[3...] {
                let token = rawToken.trimmingCharacters(in: .whitespaces)
                if token.isEmpty { continue }
                guard let colonIndex = token.firstIndex(of: ":") else { continue }

                let key = String(token[token.startIndex..<colonIndex])
                let rest = String(token[token.index(after: colonIndex)...])

                if scalarKeys.contains(key) {
                    let value = stripQuotes(rest)
                    switch key {
                    case "sm":
                        stateMachine = value
                    case "artboard":
                        artboardSpecified = true
                        artboardValue = (value == "-") ? nil : value
                    case "trigger":
                        trigger = value
                    case "note":
                        note = value
                    default:
                        break
                    }
                } else if inputTypePrefixes.contains(key) {
                    if let spec = parseParamSpec(type: key, rest: rest) {
                        inputs.append(spec)
                    }
                }
                // Unknown keys are ignored (mirrors the Python warning-and-skip behavior).
            }
        }

        let finalStateMachine = (stateMachine?.isEmpty == false) ? stateMachine! : defaultStateMachine
        let finalArtboard: String? = artboardSpecified ? artboardValue : defaultArtboard

        return CatalogItem(
            src: src,
            size: parseSize(sizeStr),
            previewSize: previewStr.isEmpty ? nil : parseSize(previewStr),
            stateMachineName: finalStateMachine,
            artboardName: finalArtboard,
            trigger: trigger,
            note: note,
            inputs: inputs
        )
    }

    // MARK: - Token value parsing

    /// Parses a `type:rest` token's value portion into a `ParamSpec`.
    /// `rest` is everything after the first colon, e.g. `StressPercent`, `text1("Nov")`,
    /// or (for lists) `BarList[num:BarHeight]`.
    private static func parseParamSpec(type: String, rest: String) -> ParamSpec? {
        if type == "list" {
            return parseListSpec(rest)
        }

        if type == "num" || type == "v_num" {
            let numeric = parseNumberSpec(rest)
            return .number(
                name: numeric.name,
                defaultValue: numeric.defaultValue,
                range: numeric.range,
                precision: numeric.precision
            )
        }

        let (name, defaultValue) = splitNameAndDefault(rest)

        switch type {
        case "bol", "v_bol":
            let boolDefault = defaultValue.map { isTruthy($0) }
            return .boolean(name: name, defaultValue: boolDefault)
        case "txt":
            return .string(name: name, defaultValue: defaultValue)
        case "col":
            return .color(name: name, defaultValue: defaultValue)
        case "img":
            return .image(name: name, defaultValue: defaultValue)
        default:
            return nil
        }
    }

    private struct NumberSpec {
        let name: String
        let defaultValue: Double?
        let range: ClosedRange<Double>?
        let precision: Int
    }

    /// Parses `Name(value)` or `Name(value:min-max)`. Precision is lexical so `1.0` retains
    /// a tenth-step slider instead of being treated as the integer literal `1`.
    private static func parseNumberSpec(_ rest: String) -> NumberSpec {
        let (name, rawValue) = splitNameAndDefault(rest)
        guard let rawValue else {
            return NumberSpec(name: name, defaultValue: nil, range: nil, precision: 0)
        }

        let components = rawValue.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let defaultRaw = String(components[0]).trimmingCharacters(in: .whitespaces)
        let defaultValue = Double(defaultRaw)

        guard components.count == 2 else {
            return NumberSpec(
                name: name,
                defaultValue: defaultValue,
                range: nil,
                precision: decimalPrecision(in: defaultRaw)
            )
        }

        let rangeRaw = String(components[1]).trimmingCharacters(in: .whitespaces)
        guard rangeRaw.count > 1,
              let separator = rangeRaw.dropFirst().firstIndex(of: "-")
        else {
            return NumberSpec(
                name: name,
                defaultValue: defaultValue,
                range: nil,
                precision: decimalPrecision(in: defaultRaw)
            )
        }

        let lowerRaw = String(rangeRaw[..<separator]).trimmingCharacters(in: .whitespaces)
        let upperRaw = String(rangeRaw[rangeRaw.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
        guard let lower = Double(lowerRaw),
              let upper = Double(upperRaw),
              lower.isFinite,
              upper.isFinite,
              lower <= upper
        else {
            return NumberSpec(
                name: name,
                defaultValue: defaultValue,
                range: nil,
                precision: decimalPrecision(in: defaultRaw)
            )
        }

        return NumberSpec(
            name: name,
            defaultValue: defaultValue,
            range: lower...upper,
            precision: max(
                decimalPrecision(in: defaultRaw),
                decimalPrecision(in: lowerRaw),
                decimalPrecision(in: upperRaw)
            )
        )
    }

    private static func decimalPrecision(in value: String) -> Int {
        guard let decimalSeparator = value.firstIndex(of: ".") else { return 0 }
        return value.distance(from: value.index(after: decimalSeparator), to: value.endIndex)
    }

    /// Splits `Name(default)` into `("Name", "default")`, stripping wrapping quotes from the
    /// default. If there is no trailing `(...)`, returns `(rest, nil)`.
    private static func splitNameAndDefault(_ rest: String) -> (name: String, defaultValue: String?) {
        let trimmed = rest.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasSuffix(")"), let openParen = trimmed.lastIndex(of: "(") else {
            return (trimmed, nil)
        }
        let name = String(trimmed[trimmed.startIndex..<openParen]).trimmingCharacters(in: .whitespaces)
        let innerStart = trimmed.index(after: openParen)
        let innerEnd = trimmed.index(before: trimmed.endIndex)
        guard innerStart <= innerEnd else { return (name, "") }
        let defaultRaw = String(trimmed[innerStart..<innerEnd]).trimmingCharacters(in: .whitespaces)
        return (name, stripQuotes(defaultRaw))
    }

    /// Parses `Name[innerType:innerName]` (only `Name[innerName]`, defaulting inner type to
    /// "num", is also accepted).
    private static func parseListSpec(_ rest: String) -> ParamSpec? {
        let trimmed = rest.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasSuffix("]"), let bracketOpen = trimmed.firstIndex(of: "[") else { return nil }

        let listName = String(trimmed[trimmed.startIndex..<bracketOpen]).trimmingCharacters(in: .whitespaces)
        let innerStart = trimmed.index(after: bracketOpen)
        let innerEnd = trimmed.index(before: trimmed.endIndex)
        guard innerStart <= innerEnd else { return nil }
        let innerSpec = String(trimmed[innerStart..<innerEnd])

        var innerType = "num"
        var innerName = innerSpec
        if let colonIdx = innerSpec.firstIndex(of: ":") {
            innerType = String(innerSpec[innerSpec.startIndex..<colonIdx])
            innerName = String(innerSpec[innerSpec.index(after: colonIdx)...])
        }
        return .list(name: listName, innerType: innerType, innerName: innerName)
    }

    private static func isTruthy(_ value: String) -> Bool {
        ["true", "1", "yes", "y", "on", "checked"].contains(value.lowercased())
    }

    private static func stripQuotes(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") else { return trimmed }
        return String(trimmed.dropFirst().dropLast())
    }

    private static func parseSize(_ value: String) -> CGSize {
        let parts = value.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let height = Double(parts[1].trimmingCharacters(in: .whitespaces))
        else {
            return .zero
        }
        return CGSize(width: width, height: height)
    }

    // MARK: - CSV line splitting

    /// A minimal CSV field splitter matching Python's `csv.reader` default (excel) dialect:
    /// commas separate fields, and a field is only treated as quoted if it *starts* with `"`
    /// (a `""` inside a quoted field is an escaped literal quote). Quotes that appear in the
    /// middle of an otherwise-unquoted field (e.g. `txt:label("value")`) are left as literal
    /// characters, exactly like the Python behavior.
    private static func splitCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]
            if inQuotes {
                if char == "\"" {
                    let next = line.index(after: index)
                    if next < line.endIndex, line[next] == "\"" {
                        current.append("\"")
                        index = line.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                        index = line.index(after: index)
                        continue
                    }
                } else {
                    current.append(char)
                    index = line.index(after: index)
                    continue
                }
            } else {
                if char == "\"" && current.isEmpty {
                    inQuotes = true
                    index = line.index(after: index)
                    continue
                } else if char == "," {
                    fields.append(current)
                    current = ""
                    index = line.index(after: index)
                    continue
                } else {
                    current.append(char)
                    index = line.index(after: index)
                    continue
                }
            }
        }
        fields.append(current)
        return fields
    }
}
