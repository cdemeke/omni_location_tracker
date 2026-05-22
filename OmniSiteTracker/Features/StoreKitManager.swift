//
//  StoreKitManager.swift
//  OmniSiteTracker
//
//  In-App Purchase management with StoreKit 2
//

import SwiftUI
import StoreKit

enum ProductID: String, CaseIterable {
    case premiumMonthly = "com.omnitracker.premium.monthly"
    case premiumYearly = "com.omnitracker.premium.yearly"
    case lifetime = "com.omnitracker.premium.lifetime"
    case tipSmall = "com.omnitracker.tip.small"
    case tipMedium = "com.omnitracker.tip.medium"
    case tipLarge = "com.omnitracker.tip.large"
}

@MainActor
@Observable
final class StoreKitManager {
    static let shared = StoreKitManager()
    
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    var isPremium: Bool {
        purchasedProductIDs.contains(ProductID.premiumMonthly.rawValue) ||
        purchasedProductIDs.contains(ProductID.premiumYearly.rawValue) ||
        purchasedProductIDs.contains(ProductID.lifetime.rawValue)
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            await updatePurchasedProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
        case .pending:
            break
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        await updatePurchasedProducts()
    }
    
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.verificationFailed
        }
    }
}

enum StoreError: Error {
    case verificationFailed
}

struct StoreKitView: View {
    @State private var store = StoreKitManager.shared
    
    var subscriptionProducts: [Product] {
        store.products.filter { $0.type == .autoRenewable }
    }
    
    var tipProducts: [Product] {
        store.products.filter { $0.type == .consumable }
    }
    
    var body: some View {
        List {
            if store.isPremium {
                Section {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("Premium Active")
                            .font(.headline)
                    }
                }
            }
            
            Section("Premium Features") {
                ForEach(subscriptionProducts, id: \.id) { product in
                    ProductRow(product: product, isPurchased: store.purchasedProductIDs.contains(product.id)) {
                        Task {
                            try? await store.purchase(product)
                        }
                    }
                }
            }
            
            Section("Support Development") {
                ForEach(tipProducts, id: \.id) { product in
                    ProductRow(product: product, isPurchased: false) {
                        Task {
                            try? await store.purchase(product)
                        }
                    }
                }
            }
            
            Section {
                Button("Restore Purchases") {
                    Task {
                        await store.restorePurchases()
                    }
                }
            }
            
            if let error = store.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Premium")
        .task {
            await store.loadProducts()
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(product.displayPrice) {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    NavigationStack {
        StoreKitView()
    }
}
