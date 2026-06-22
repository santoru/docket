// TipJarView.swift
// Docket — Tip Jar UI

import SwiftUI
import StoreKit

struct TipJarView: View {
    @State private var tipJar = TipJar.shared
    @State private var thankYou = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tip Jar").font(.body.weight(.medium))
            Text("Docket is a one-time purchase with no subscriptions. If you enjoy it, tips are appreciated! ☕")
                .font(.caption)
                .foregroundStyle(.secondary)

            if tipJar.products.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 8) {
                    ForEach(tipJar.products, id: \.id) { product in
                        Button {
                            Task {
                                if await tipJar.purchase(product) {
                                    thankYou = true
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(emoji(for: product))
                                Text(product.displayPrice)
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                        .disabled(tipJar.isPurchasing)
                    }
                }
            }

            if thankYou {
                Text("Thank you for your support! 💚")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .task { await tipJar.loadProducts() }
    }

    private func emoji(for product: Product) -> String {
        switch product.id {
        case _ where product.id.hasSuffix(".small"): return "☕"
        case _ where product.id.hasSuffix(".medium"): return "🍕"
        default: return "🎉"
        }
    }
}
