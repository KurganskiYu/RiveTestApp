//
//  RiveWorkerProvider.swift
//  RiveTestApp
//
//  Provides a single shared Rive `Worker` (background processing thread) for the whole app,
//  per the "keep it simple" architecture decision.
//

import RiveRuntime

@MainActor
final class RiveWorkerProvider {
    static let shared = RiveWorkerProvider()

    private var cachedWorker: Worker?

    private init() {}

    func worker() async throws -> Worker {
        if let cachedWorker {
            return cachedWorker
        }
        let worker = try await Worker()
        cachedWorker = worker
        return worker
    }
}
