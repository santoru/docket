// TipJar.swift
// Docket — In-App Tips via StoreKit 2

import StoreKit
import os

@Observable
@MainActor
final class TipJar {
    static let shared = TipJar()

    /// Drives the Tip Jar UI: show a spinner while loading, the tip buttons once
    /// loaded, or an "unavailable" message if the App Store could not be reached.
    enum LoadState {
        case loading
        case loaded
        case failed
    }

    private(set) var products: [Product] = []
    private(set) var loadState: LoadState = .loading
    private(set) var isPurchasing = false

    private let logger = Logger(subsystem: "blog.insecurity.docket", category: "tip-jar")

    private let productIDs = [
        "blog.insecurity.Docket.tip.small",
        "blog.insecurity.Docket.tip.medium",
        "blog.insecurity.Docket.tip.large"
    ]

    private init() {
        // Finish transactions that arrive outside the normal purchase flow
        // (Ask-to-Buy approvals, interrupted purchases, retries). The task runs
        // for the app's lifetime; its infinite loop keeps it alive, so there is
        // nothing to retain or cancel.
        Task(priority: .background) {
            for await update in Transaction.updates {
                // Tips are consumables with nothing to unlock — just finish the
                // transaction so StoreKit stops redelivering it.
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
            }
        }
    }

    func loadProducts() async {
        loadState = .loading
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
            loadState = products.isEmpty ? .failed : .loaded
        } catch {
            logger.error("Failed to load tip products: \(error.localizedDescription)")
            loadState = .failed
        }
    }

    /// Returns true only when a verified purchase completed.
    func purchase(_ product: Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            logger.error("Tip purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.unverified
        case .verified(let value): return value
        }
    }

    private enum StoreError: Error { case unverified }
}
