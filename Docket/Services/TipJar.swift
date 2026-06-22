// TipJar.swift
// Docket — In-App Tips via StoreKit 2

import StoreKit

@Observable
final class TipJar {
    static let shared = TipJar()

    private(set) var products: [Product] = []
    private(set) var isPurchasing = false

    private let productIDs = [
        "blog.insecurity.Docket.tip.small",
        "blog.insecurity.Docket.tip.medium",
        "blog.insecurity.Docket.tip.large"
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load tips: \(error)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
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
