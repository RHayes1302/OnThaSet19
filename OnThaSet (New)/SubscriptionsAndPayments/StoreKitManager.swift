//
//  StoreKitManager.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import Foundation
import StoreKit
import SwiftUI

// Type alias to resolve Transaction ambiguity
typealias SKTransaction = StoreKit.Transaction

@MainActor
class StoreKitManager: ObservableObject {
    // Product IDs — must match App Store Connect exactly
    private let singlePostID = "com.onthaset.singlepost"
    private let monthlySubscriptionID = "com.hayesenterprisellc.onthaset.membership.monthly"
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var hasActiveSubscription = false
    @Published var isLoading = false
    
    private var updateListenerTask: Task<Void, Never>?
    
    init() {
        print("🚀 StoreKitManager initialized")
        updateListenerTask = listenForTransactions()
        Task {
            print("📱 Starting to load products...")
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        print("🔍 Attempting to load products with IDs:")
        print("   1. \(singlePostID)")
        print("   2. \(monthlySubscriptionID)")
        
        do {
            let loadedProducts = try await Product.products(for: [singlePostID, monthlySubscriptionID])
            
            print("✅ Product.products() returned \(loadedProducts.count) products")
            
            if loadedProducts.isEmpty {
                print("⚠️ WARNING: No products were returned!")
                print("   This usually means:")
                print("   1. StoreKit Configuration file is not created")
                print("   2. Product IDs don't match")
                print("   3. StoreKit Configuration is not selected in scheme")
            } else {
                for product in loadedProducts {
                    print("   ✅ Found: \(product.id)")
                    print("      Name: \(product.displayName)")
                    print("      Price: \(product.displayPrice)")
                    print("      Type: \(product.type)")
                }
            }
            
            self.products = loadedProducts.sorted { $0.price < $1.price }
            print("📦 Final products array has \(self.products.count) items")
            
        } catch {
            print("❌ CRITICAL ERROR loading products:")
            print("   Error: \(error)")
            print("   Description: \(error.localizedDescription)")
            
            if let storeError = error as? StoreKitError {
                print("   StoreKit Error Code: \(storeError)")
            }
        }
    }
    
    // MARK: - Purchase Product
    
    func purchase(_ product: Product) async throws -> SKTransaction? {
        isLoading = true
        defer { isLoading = false }
        
        print("💳 Starting purchase for: \(product.displayName)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            print("✅ Purchase successful: \(product.displayName)")
            return transaction
            
        case .userCancelled:
            print("⚠️ User cancelled purchase")
            return nil
            
        case .pending:
            print("⏳ Purchase pending")
            return nil
            
        @unknown default:
            print("❓ Unknown purchase result")
            return nil
        }
    }
    
    // MARK: - Check Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            print("❌ Transaction verification failed")
            throw StoreError.failedVerification
        case .verified(let safe):
            print("✅ Transaction verified")
            return safe
        }
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        print("🔄 Updating purchased products...")
        var newPurchasedIDs: Set<String> = []
        var hasSubscription = false
        
        for await result in SKTransaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == monthlySubscriptionID {
                    hasSubscription = true
                    print("   ✅ Active subscription found")
                }
                
                newPurchasedIDs.insert(transaction.productID)
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }
        
        self.purchasedProductIDs = newPurchasedIDs
        self.hasActiveSubscription = hasSubscription
        
        print("📦 Active purchases: \(newPurchasedIDs)")
        print("📅 Has subscription: \(hasSubscription)")
    }
    
    // MARK: - Listen for Transactions
    
    nonisolated func listenForTransactions() -> Task<Void, Never> {
        return Task {
            print("👂 Listening for transaction updates...")
            for await verificationResult in SKTransaction.updates {
                guard case .verified(let transaction) = verificationResult else {
                    print("❌ Transaction failed verification")
                    continue
                }
                
                print("🔔 New transaction received: \(transaction.productID)")
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        isLoading = true
        defer { isLoading = false }
        
        try? await AppStore.sync()
        await updatePurchasedProducts()
        print("✅ Restore complete")
    }
    
    // MARK: - Helper Properties
    
    var singlePostProduct: Product? {
        let product = products.first { $0.id == singlePostID }
        print("🔍 Single post product: \(product?.displayName ?? "Not found")")
        return product
    }
    
    var subscriptionProduct: Product? {
        let product = products.first { $0.id == monthlySubscriptionID }
        print("🔍 Subscription product: \(product?.displayName ?? "Not found")")
        return product
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
