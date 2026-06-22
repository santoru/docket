// TipJarView.swift
// Docket — Tip Jar UI

import SwiftUI
import StoreKit

struct TipJarView: View {
    @State private var tipJar = TipJar.shared
    @State private var thankYou = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tipJar).font(.body.weight(.medium))
            Text(L10n.tipJarBlurb)
                .font(.caption)
                .foregroundStyle(.secondary)

            switch tipJar.loadState {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            case .failed:
                Text(L10n.tipJarUnavailable)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            case .loaded:
                HStack(spacing: 8) {
                    ForEach(tipJar.products, id: \.id) { product in
                        tipButton(product)
                    }
                }
            }

            if thankYou {
                Text(L10n.tipJarThankYou)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .task { await tipJar.loadProducts() }
    }

    private func tipButton(_ product: Product) -> some View {
        Button {
            Task {
                if await tipJar.purchase(product) {
                    withAnimation { thankYou = true }
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

    private func emoji(for product: Product) -> String {
        if product.id.hasSuffix(".small") { return "☕" }
        if product.id.hasSuffix(".medium") { return "🍕" }
        return "🎉"
    }
}
